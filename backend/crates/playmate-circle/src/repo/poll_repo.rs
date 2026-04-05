//! 投票数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::Poll;

const POLL_COLS: &str =
    "id, creator_id, title, pro_argument, con_argument, pro_count, con_count, created_at";

pub async fn list_polls(pool: &PgPool, limit: i64, offset: i64) -> AppResult<Vec<Poll>> {
    sqlx::query_as::<_, Poll>(&format!(
        "SELECT {POLL_COLS} FROM polls ORDER BY created_at DESC LIMIT $1 OFFSET $2"
    ))
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create_poll(
    pool: &PgPool,
    creator_id: Uuid,
    title: &str,
    pro_argument: &str,
    con_argument: &str,
) -> AppResult<Poll> {
    sqlx::query_as::<_, Poll>(&format!(
        "INSERT INTO polls (creator_id, title, pro_argument, con_argument)
         VALUES ($1, $2, $3, $4)
         RETURNING {POLL_COLS}"
    ))
    .bind(creator_id)
    .bind(title)
    .bind(pro_argument)
    .bind(con_argument)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 投票（每用户只能投一次，重复投票视为改票）
pub async fn vote(pool: &PgPool, poll_id: Uuid, user_id: Uuid, side: i16) -> AppResult<Poll> {
    if side != 1 && side != 2 {
        return Err(AppError::BadRequest("side 必须为 1（正方）或 2（反方）".to_string()));
    }

    let mut tx = pool.begin().await?;

    // 查是否已投票
    let existing: Option<(i16,)> = sqlx::query_as(
        "SELECT side FROM poll_votes WHERE poll_id = $1 AND user_id = $2",
    )
    .bind(poll_id)
    .bind(user_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    if let Some((old_side,)) = existing {
        if old_side == side {
            // 已投相同立场，幂等返回
            tx.rollback().await?;
            let poll = get_poll(&*pool, poll_id).await?;
            return Ok(poll);
        }
        // 改票：撤旧票，加新票
        sqlx::query("UPDATE poll_votes SET side = $3 WHERE poll_id = $1 AND user_id = $2")
            .bind(poll_id)
            .bind(user_id)
            .bind(side)
            .execute(&mut *tx)
            .await
            .map_err(AppError::Database)?;

        let (dec_col, inc_col) = if old_side == 1 {
            ("pro_count", "con_count")
        } else {
            ("con_count", "pro_count")
        };
        sqlx::query(&format!(
            "UPDATE polls SET {dec_col} = GREATEST({dec_col} - 1, 0), {inc_col} = {inc_col} + 1 WHERE id = $1"
        ))
        .bind(poll_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;
    } else {
        // 首次投票
        sqlx::query(
            "INSERT INTO poll_votes (poll_id, user_id, side) VALUES ($1, $2, $3)",
        )
        .bind(poll_id)
        .bind(user_id)
        .bind(side)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;

        let inc_col = if side == 1 { "pro_count" } else { "con_count" };
        sqlx::query(&format!(
            "UPDATE polls SET {inc_col} = {inc_col} + 1 WHERE id = $1"
        ))
        .bind(poll_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;
    }

    let poll: Poll = sqlx::query_as::<_, Poll>(&format!(
        "SELECT {POLL_COLS} FROM polls WHERE id = $1"
    ))
    .bind(poll_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("投票 {} 不存在", poll_id)))?;

    tx.commit().await?;
    Ok(poll)
}

async fn get_poll(pool: &PgPool, poll_id: Uuid) -> AppResult<Poll> {
    sqlx::query_as::<_, Poll>(&format!(
        "SELECT {POLL_COLS} FROM polls WHERE id = $1"
    ))
    .bind(poll_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("投票 {} 不存在", poll_id)))
}
