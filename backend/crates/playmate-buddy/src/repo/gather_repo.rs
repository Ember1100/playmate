//! 搭子局数据库查询

use std::collections::{HashMap, HashSet};

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{BuddyGather, BuddyGatherWithStats};

// ── 列名常量 ─────────────────────────────────────────────────────────────────

const GATHER_COLS: &str =
    "id, creator_id, title, location, landmark, start_time, end_time,
     first_menu_id, second_menu_id, capacity, description, vibes,
     activity_mode, status, group_id, created_at,
     schedule, deadline, fee_type, fee_amount,
     age_min, age_max, gender_pref, cover_url,
     require_real_name, require_review, allow_transfer";

// ── 创建搭子局 ────────────────────────────────────────────────────────────────

pub async fn create(
    pool:              &PgPool,
    creator_id:        Uuid,
    title:             &str,
    location:          Option<&str>,
    landmark:          Option<&str>,
    start_time:        chrono::DateTime<chrono::Utc>,
    end_time:          chrono::DateTime<chrono::Utc>,
    first_menu_id:     Option<i64>,
    second_menu_id:    Option<i64>,
    capacity:          i32,
    description:       Option<&str>,
    vibes:             &[String],
    activity_mode:     &str,
    schedule:          Option<&str>,
    deadline:          Option<chrono::DateTime<chrono::Utc>>,
    fee_type:          i16,
    fee_amount:        Option<f64>,
    age_min:           i16,
    age_max:           i16,
    gender_pref:       i16,
    cover_url:         Option<&str>,
    require_real_name: bool,
    require_review:    bool,
    allow_transfer:    bool,
) -> AppResult<BuddyGather> {
    // Step 1：创建对应的群聊
    let (group_id,): (Uuid,) = sqlx::query_as(
        "INSERT INTO social_groups (creator_id, name, category, is_public, member_count)
         VALUES ($1, $2, '搭子局', false, 0)
         RETURNING id",
    )
    .bind(creator_id)
    .bind(title)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 2：创建搭子局，绑定 group_id
    let gather = sqlx::query_as::<_, BuddyGather>(&format!(
        "INSERT INTO buddy_gathers
             (creator_id, title, location, landmark, start_time, end_time,
              first_menu_id, second_menu_id, capacity, description, vibes, activity_mode,
              group_id, schedule, deadline, fee_type, fee_amount,
              age_min, age_max, gender_pref, cover_url,
              require_real_name, require_review, allow_transfer)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24)
         RETURNING {GATHER_COLS}"
    ))
    .bind(creator_id)
    .bind(title)
    .bind(location)
    .bind(landmark)
    .bind(start_time)
    .bind(end_time)
    .bind(first_menu_id)
    .bind(second_menu_id)
    .bind(capacity)
    .bind(description)
    .bind(vibes)
    .bind(activity_mode)
    .bind(group_id)
    .bind(schedule)
    .bind(deadline)
    .bind(fee_type)
    .bind(fee_amount)
    .bind(age_min)
    .bind(age_max)
    .bind(gender_pref)
    .bind(cover_url)
    .bind(require_real_name)
    .bind(require_review)
    .bind(allow_transfer)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    Ok(gather)
}

// ── 搭子局列表（分步查询，按一级菜单分页）────────────────────────────────────

pub async fn list(
    pool:            &PgPool,
    current_user_id: Uuid,
    first_menu_id:   Option<i64>,
    limit:           i64,
    offset:          i64,
) -> AppResult<Vec<BuddyGatherWithStats>> {
    // Step 1：单表查询 buddy_gathers
    let gathers: Vec<BuddyGather> = match first_menu_id {
        Some(mid) => sqlx::query_as::<_, BuddyGather>(&format!(
            "SELECT {GATHER_COLS} FROM buddy_gathers
             WHERE status = 0 AND first_menu_id = $1
             ORDER BY created_at DESC LIMIT $2 OFFSET $3"
        ))
        .bind(mid)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?,

        None => sqlx::query_as::<_, BuddyGather>(&format!(
            "SELECT {GATHER_COLS} FROM buddy_gathers
             WHERE status = 0
             ORDER BY created_at DESC LIMIT $1 OFFSET $2"
        ))
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?,
    };

    if gathers.is_empty() {
        return Ok(vec![]);
    }

    // Step 2：收集 IDs
    let gather_ids: Vec<Uuid> = gathers.iter().map(|g| g.id).collect();
    let creator_ids: Vec<Uuid> = gathers.iter().map(|g| g.creator_id).collect();

    // 收集需要查询名称的 menu_id
    let mut menu_ids: Vec<i64> = Vec::new();
    for g in &gathers {
        if let Some(id) = g.first_menu_id  { menu_ids.push(id); }
        if let Some(id) = g.second_menu_id { menu_ids.push(id); }
    }
    menu_ids.dedup();

    // Step 3：查询创建者信息
    let creators: Vec<(Uuid, String, Option<String>)> = sqlx::query_as(
        "SELECT id, username, avatar_url FROM users WHERE id = ANY($1)",
    )
    .bind(&creator_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let creator_map: HashMap<Uuid, (String, Option<String>)> = creators
        .into_iter()
        .map(|(id, username, avatar)| (id, (username, avatar)))
        .collect();

    // Step 4：查询菜单名称
    let menu_name_map: HashMap<i64, String> = if !menu_ids.is_empty() {
        let rows: Vec<(i64, String)> = sqlx::query_as(
            "SELECT id, name FROM menus WHERE id = ANY($1)",
        )
        .bind(&menu_ids)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?;
        rows.into_iter().collect()
    } else {
        HashMap::new()
    };

    // Step 5：参与人数
    let counts: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT gather_id, COUNT(*)::BIGINT
         FROM buddy_gather_members
         WHERE gather_id = ANY($1)
         GROUP BY gather_id",
    )
    .bind(&gather_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let count_map: HashMap<Uuid, i64> = counts.into_iter().collect();

    // Step 6：当前用户已参加哪些
    let joined: Vec<(Uuid,)> = sqlx::query_as(
        "SELECT gather_id FROM buddy_gather_members
         WHERE gather_id = ANY($1) AND user_id = $2",
    )
    .bind(&gather_ids)
    .bind(current_user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let joined_set: HashSet<Uuid> = joined.into_iter().map(|(id,)| id).collect();

    // Step 7：成员信息（最多 5 人，含无头像用户）
    let member_rows: Vec<(Uuid, String, Option<String>)> = sqlx::query_as(
        "SELECT bgm.gather_id, u.username, u.avatar_url
         FROM buddy_gather_members bgm
         JOIN users u ON u.id = bgm.user_id
         WHERE bgm.gather_id = ANY($1)
         ORDER BY bgm.joined_at",
    )
    .bind(&gather_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    // gather_id → Vec<(username, avatar_url)>
    let mut members_map: HashMap<Uuid, Vec<(String, Option<String>)>> = HashMap::new();
    for (gather_id, username, avatar) in member_rows {
        let v = members_map.entry(gather_id).or_default();
        if v.len() < 5 {
            v.push((username, avatar));
        }
    }

    // Step 8：组装结果
    let result = gathers
        .into_iter()
        .map(|g| {
            let (creator_username, creator_avatar) = creator_map
                .get(&g.creator_id)
                .cloned()
                .unwrap_or_else(|| ("未知用户".to_string(), None));
            let first_menu_name  = g.first_menu_id.and_then(|id| menu_name_map.get(&id).cloned());
            let second_menu_name = g.second_menu_id.and_then(|id| menu_name_map.get(&id).cloned());
            let members = members_map.remove(&g.id).unwrap_or_default();
            let member_avatars   = members.iter().map(|(_, av)| av.clone().unwrap_or_default()).collect();
            let member_usernames = members.into_iter().map(|(un, _)| un).collect();
            BuddyGatherWithStats {
                id:               g.id,
                creator_id:       g.creator_id,
                creator_username,
                creator_avatar,
                title:            g.title,
                location:         g.location,
                landmark:         g.landmark,
                start_time:       g.start_time,
                end_time:         g.end_time,
                first_menu_id:    g.first_menu_id,
                first_menu_name,
                second_menu_id:   g.second_menu_id,
                second_menu_name,
                capacity:         g.capacity,
                description:      g.description,
                vibes:            g.vibes,
                activity_mode:    g.activity_mode,
                status:           g.status,
                group_id:         g.group_id,
                created_at:       g.created_at,
                schedule:         g.schedule,
                deadline:         g.deadline,
                fee_type:         g.fee_type,
                fee_amount:       g.fee_amount,
                age_min:          g.age_min,
                age_max:          g.age_max,
                gender_pref:      g.gender_pref,
                cover_url:        g.cover_url,
                require_real_name: g.require_real_name,
                require_review:   g.require_review,
                allow_transfer:   g.allow_transfer,
                joined_count:     count_map.get(&g.id).copied().unwrap_or(0),
                is_joined:        joined_set.contains(&g.id),
                member_avatars,
                member_usernames,
            }
        })
        .collect();

    Ok(result)
}

// ── 搜索搭子局（关键词匹配标题/描述） ────────────────────────────────────────

pub async fn search(
    pool:            &PgPool,
    current_user_id: Uuid,
    keyword:         &str,
    limit:           i64,
    offset:          i64,
) -> AppResult<(Vec<BuddyGatherWithStats>, i64)> {
    let pattern = format!("%{}%", keyword);

    // Step 1: 匹配关键词的搭子局
    let gathers: Vec<BuddyGather> = sqlx::query_as::<_, BuddyGather>(&format!(
        "SELECT {GATHER_COLS} FROM buddy_gathers
         WHERE status = 0 AND (title ILIKE $1 OR description ILIKE $1)
         ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    ))
    .bind(&pattern)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 2: 总数
    let (total,): (i64,) = sqlx::query_as(
        "SELECT COUNT(*)::BIGINT FROM buddy_gathers
         WHERE status = 0 AND (title ILIKE $1 OR description ILIKE $1)",
    )
    .bind(&pattern)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    if gathers.is_empty() {
        return Ok((vec![], total));
    }

    let gather_ids:  Vec<Uuid> = gathers.iter().map(|g| g.id).collect();
    let creator_ids: Vec<Uuid> = gathers.iter().map(|g| g.creator_id).collect();

    let mut menu_ids: Vec<i64> = Vec::new();
    for g in &gathers {
        if let Some(id) = g.first_menu_id  { menu_ids.push(id); }
        if let Some(id) = g.second_menu_id { menu_ids.push(id); }
    }
    menu_ids.dedup();

    // Step 3: 创建者信息
    let creators: Vec<(Uuid, String, Option<String>)> = sqlx::query_as(
        "SELECT id, username, avatar_url FROM users WHERE id = ANY($1)",
    )
    .bind(&creator_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let creator_map: HashMap<Uuid, (String, Option<String>)> = creators
        .into_iter()
        .map(|(id, username, avatar)| (id, (username, avatar)))
        .collect();

    // Step 4: 菜单名称
    let menu_name_map: HashMap<i64, String> = if !menu_ids.is_empty() {
        let rows: Vec<(i64, String)> = sqlx::query_as(
            "SELECT id, name FROM menus WHERE id = ANY($1)",
        )
        .bind(&menu_ids)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?;
        rows.into_iter().collect()
    } else {
        HashMap::new()
    };

    // Step 5: 参与人数
    let counts: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT gather_id, COUNT(*)::BIGINT
         FROM buddy_gather_members
         WHERE gather_id = ANY($1)
         GROUP BY gather_id",
    )
    .bind(&gather_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let count_map: HashMap<Uuid, i64> = counts.into_iter().collect();

    // Step 6: 当前用户已参加哪些
    let joined: Vec<(Uuid,)> = sqlx::query_as(
        "SELECT gather_id FROM buddy_gather_members
         WHERE gather_id = ANY($1) AND user_id = $2",
    )
    .bind(&gather_ids)
    .bind(current_user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let joined_set: HashSet<Uuid> = joined.into_iter().map(|(id,)| id).collect();

    // Step 7: 成员信息（最多 5 人）
    let member_rows: Vec<(Uuid, String, Option<String>)> = sqlx::query_as(
        "SELECT bgm.gather_id, u.username, u.avatar_url
         FROM buddy_gather_members bgm
         JOIN users u ON u.id = bgm.user_id
         WHERE bgm.gather_id = ANY($1)
         ORDER BY bgm.joined_at",
    )
    .bind(&gather_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let mut members_map: HashMap<Uuid, Vec<(String, Option<String>)>> = HashMap::new();
    for (gather_id, username, avatar) in member_rows {
        let v = members_map.entry(gather_id).or_default();
        if v.len() < 5 { v.push((username, avatar)); }
    }

    // Step 8: 组装
    let result = gathers
        .into_iter()
        .map(|g| {
            let (creator_username, creator_avatar) = creator_map
                .get(&g.creator_id)
                .cloned()
                .unwrap_or_else(|| ("未知用户".to_string(), None));
            let first_menu_name  = g.first_menu_id.and_then(|id| menu_name_map.get(&id).cloned());
            let second_menu_name = g.second_menu_id.and_then(|id| menu_name_map.get(&id).cloned());
            let members = members_map.remove(&g.id).unwrap_or_default();
            let member_avatars   = members.iter().map(|(_, av)| av.clone().unwrap_or_default()).collect();
            let member_usernames = members.into_iter().map(|(un, _)| un).collect();
            BuddyGatherWithStats {
                id: g.id, creator_id: g.creator_id,
                creator_username, creator_avatar,
                title: g.title, location: g.location, landmark: g.landmark,
                start_time: g.start_time, end_time: g.end_time,
                first_menu_id: g.first_menu_id, first_menu_name,
                second_menu_id: g.second_menu_id, second_menu_name,
                capacity: g.capacity, description: g.description,
                vibes: g.vibes, activity_mode: g.activity_mode,
                status: g.status, group_id: g.group_id,
                created_at: g.created_at,
                schedule: g.schedule, deadline: g.deadline,
                fee_type: g.fee_type, fee_amount: g.fee_amount,
                age_min: g.age_min, age_max: g.age_max,
                gender_pref: g.gender_pref, cover_url: g.cover_url,
                require_real_name: g.require_real_name,
                require_review: g.require_review,
                allow_transfer: g.allow_transfer,
                joined_count: count_map.get(&g.id).copied().unwrap_or(0),
                is_joined:    joined_set.contains(&g.id),
                member_avatars,
                member_usernames,
            }
        })
        .collect();

    Ok((result, total))
}

// ── 搭子局详情（分步查询） ────────────────────────────────────────────────────

pub async fn get(
    pool:            &PgPool,
    current_user_id: Uuid,
    gather_id:       Uuid,
) -> AppResult<BuddyGatherWithStats> {
    // Step 1：单表查询搭子局
    let g = sqlx::query_as::<_, BuddyGather>(&format!(
        "SELECT {GATHER_COLS} FROM buddy_gathers WHERE id = $1"
    ))
    .bind(gather_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound("搭子局不存在".to_string()))?;

    // Step 2：查询创建者
    let creator: Option<(String, Option<String>)> = sqlx::query_as(
        "SELECT username, avatar_url FROM users WHERE id = $1",
    )
    .bind(g.creator_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;
    let (creator_username, creator_avatar) =
        creator.unwrap_or_else(|| ("未知用户".to_string(), None));

    // Step 3：查询菜单名称
    let mut menu_ids: Vec<i64> = Vec::new();
    if let Some(id) = g.first_menu_id  { menu_ids.push(id); }
    if let Some(id) = g.second_menu_id { menu_ids.push(id); }
    let menu_name_map: HashMap<i64, String> = if !menu_ids.is_empty() {
        let rows: Vec<(i64, String)> = sqlx::query_as(
            "SELECT id, name FROM menus WHERE id = ANY($1)",
        )
        .bind(&menu_ids)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?;
        rows.into_iter().collect()
    } else {
        HashMap::new()
    };
    let first_menu_name  = g.first_menu_id.and_then(|id| menu_name_map.get(&id).cloned());
    let second_menu_name = g.second_menu_id.and_then(|id| menu_name_map.get(&id).cloned());

    // Step 4：参与人数
    let (joined_count,): (i64,) = sqlx::query_as(
        "SELECT COUNT(*)::BIGINT FROM buddy_gather_members WHERE gather_id = $1",
    )
    .bind(gather_id)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 5：当前用户是否已参加
    let is_joined: bool = sqlx::query_as::<_, (bool,)>(
        "SELECT EXISTS(SELECT 1 FROM buddy_gather_members WHERE gather_id = $1 AND user_id = $2)",
    )
    .bind(gather_id)
    .bind(current_user_id)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?
    .0;

    // Step 6：成员信息（最多 5 人，含无头像用户）
    let member_rows: Vec<(String, Option<String>)> = sqlx::query_as(
        "SELECT u.username, u.avatar_url
         FROM buddy_gather_members bgm
         JOIN users u ON u.id = bgm.user_id
         WHERE bgm.gather_id = $1
         ORDER BY bgm.joined_at
         LIMIT 5",
    )
    .bind(gather_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let member_avatars:   Vec<String> = member_rows.iter().map(|(_, av)| av.clone().unwrap_or_default()).collect();
    let member_usernames: Vec<String> = member_rows.into_iter().map(|(un, _)| un).collect();

    Ok(BuddyGatherWithStats {
        id: g.id,
        creator_id: g.creator_id,
        creator_username,
        creator_avatar,
        title: g.title,
        location: g.location,
        landmark: g.landmark,
        start_time: g.start_time,
        end_time: g.end_time,
        first_menu_id: g.first_menu_id,
        first_menu_name,
        second_menu_id: g.second_menu_id,
        second_menu_name,
        capacity: g.capacity,
        description: g.description,
        vibes: g.vibes,
        activity_mode: g.activity_mode,
        status: g.status,
        group_id: g.group_id,
        created_at: g.created_at,
        schedule: g.schedule,
        deadline: g.deadline,
        fee_type: g.fee_type,
        fee_amount: g.fee_amount,
        age_min: g.age_min,
        age_max: g.age_max,
        gender_pref: g.gender_pref,
        cover_url: g.cover_url,
        require_real_name: g.require_real_name,
        require_review: g.require_review,
        allow_transfer: g.allow_transfer,
        joined_count,
        is_joined,
        member_avatars,
        member_usernames,
    })
}

// ── 参加搭子局 ────────────────────────────────────────────────────────────────

pub async fn join(
    pool:      &PgPool,
    gather_id: Uuid,
    user_id:   Uuid,
) -> AppResult<()> {
    let gather = sqlx::query_as::<_, BuddyGather>(&format!(
        "SELECT {GATHER_COLS} FROM buddy_gathers WHERE id = $1"
    ))
    .bind(gather_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound("搭子局不存在".to_string()))?;

    if gather.status != 0 {
        return Err(AppError::Business("该搭子局已关闭".to_string()));
    }

    let already: Option<(i64,)> = sqlx::query_as(
        "SELECT 1 FROM buddy_gather_members WHERE gather_id = $1 AND user_id = $2",
    )
    .bind(gather_id)
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    if already.is_some() {
        return Err(AppError::Business("你已经参加了该搭子局".to_string()));
    }

    let (joined_count,): (i64,) =
        sqlx::query_as("SELECT COUNT(*)::BIGINT FROM buddy_gather_members WHERE gather_id = $1")
            .bind(gather_id)
            .fetch_one(pool)
            .await
            .map_err(AppError::Database)?;

    if joined_count >= gather.capacity as i64 {
        return Err(AppError::Business("名额已满".to_string()));
    }

    sqlx::query("INSERT INTO buddy_gather_members (gather_id, user_id) VALUES ($1, $2)")
        .bind(gather_id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;

    if joined_count + 1 >= gather.capacity as i64 {
        sqlx::query("UPDATE buddy_gathers SET status = 1 WHERE id = $1")
            .bind(gather_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;
    }

    if let Some(group_id) = gather.group_id {
        sqlx::query(
            "INSERT INTO social_group_members (group_id, user_id)
             VALUES ($1, $2)
             ON CONFLICT DO NOTHING",
        )
        .bind(group_id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;

        sqlx::query("UPDATE social_groups SET member_count = member_count + 1 WHERE id = $1")
            .bind(group_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;

        let username: Option<(String,)> =
            sqlx::query_as("SELECT username FROM users WHERE id = $1")
                .bind(user_id)
                .fetch_optional(pool)
                .await
                .map_err(AppError::Database)?;

        let content = format!(
            "{} 加入了搭子局",
            username.map(|(u,)| u).unwrap_or_else(|| "新成员".to_string())
        );
        sqlx::query(
            "INSERT INTO social_group_messages (group_id, sender_id, type, content)
             VALUES ($1, NULL, 99, $2)",
        )
        .bind(group_id)
        .bind(content)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    }

    Ok(())
}

// ── 退出搭子局 ────────────────────────────────────────────────────────────────

pub async fn leave(
    pool:      &PgPool,
    gather_id: Uuid,
    user_id:   Uuid,
) -> AppResult<()> {
    let gather: Option<BuddyGather> = sqlx::query_as::<_, BuddyGather>(&format!(
        "SELECT {GATHER_COLS} FROM buddy_gathers WHERE id = $1"
    ))
    .bind(gather_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    let result =
        sqlx::query("DELETE FROM buddy_gather_members WHERE gather_id = $1 AND user_id = $2")
            .bind(gather_id)
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;

    if result.rows_affected() == 0 {
        return Err(AppError::Business("你未参加该搭子局".to_string()));
    }

    sqlx::query(
        "UPDATE buddy_gathers SET status = 0 WHERE id = $1 AND status = 1",
    )
    .bind(gather_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;

    if let Some(gather) = gather {
        if let Some(group_id) = gather.group_id {
            sqlx::query(
                "DELETE FROM social_group_members WHERE group_id = $1 AND user_id = $2",
            )
            .bind(group_id)
            .bind(user_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;

            sqlx::query(
                "UPDATE social_groups SET member_count = GREATEST(member_count - 1, 0) WHERE id = $1",
            )
            .bind(group_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;

            let username: Option<(String,)> =
                sqlx::query_as("SELECT username FROM users WHERE id = $1")
                    .bind(user_id)
                    .fetch_optional(pool)
                    .await
                    .map_err(AppError::Database)?;

            let content = format!(
                "{} 退出了搭子局",
                username.map(|(u,)| u).unwrap_or_else(|| "成员".to_string())
            );
            sqlx::query(
                "INSERT INTO social_group_messages (group_id, sender_id, type, content)
                 VALUES ($1, NULL, 99, $2)",
            )
            .bind(group_id)
            .bind(content)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;
        }
    }

    Ok(())
}

// ── 取消搭子局（仅创建者） ────────────────────────────────────────────────────

pub async fn cancel(
    pool:       &PgPool,
    gather_id:  Uuid,
    creator_id: Uuid,
) -> AppResult<()> {
    let result =
        sqlx::query("UPDATE buddy_gathers SET status = 2 WHERE id = $1 AND creator_id = $2")
            .bind(gather_id)
            .bind(creator_id)
            .execute(pool)
            .await
            .map_err(AppError::Database)?;

    if result.rows_affected() == 0 {
        return Err(AppError::Forbidden("无权操作该搭子局".to_string()));
    }

    Ok(())
}
