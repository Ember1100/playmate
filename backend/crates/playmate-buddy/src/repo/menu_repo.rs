//! 菜单数据库查询

use std::collections::HashMap;

use sqlx::PgPool;

use playmate_common::error::{AppError, AppResult};

use crate::dto::{MenuItemResponse, SubMenuItemResponse};

/// 查询指定类型的完整菜单树（两级）
pub async fn list_menu_tree(pool: &PgPool, menu_type: i16) -> AppResult<Vec<MenuItemResponse>> {
    // Step 1：查询一级菜单
    let first_level: Vec<(i64, String, i32)> = sqlx::query_as(
        "SELECT id, name, sort FROM menus
         WHERE parent_id IS NULL AND type = $1 AND status = 1
         ORDER BY sort",
    )
    .bind(menu_type)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if first_level.is_empty() {
        return Ok(vec![]);
    }

    let first_ids: Vec<i64> = first_level.iter().map(|(id, _, _)| *id).collect();

    // Step 2：批量查询二级菜单
    let second_level: Vec<(i64, i64, String, i32)> = sqlx::query_as(
        "SELECT id, parent_id, name, sort FROM menus
         WHERE parent_id = ANY($1) AND status = 1
         ORDER BY sort",
    )
    .bind(&first_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 3：按 parent_id 分组
    let mut children_map: HashMap<i64, Vec<SubMenuItemResponse>> = HashMap::new();
    for (id, parent_id, name, sort) in second_level {
        children_map
            .entry(parent_id)
            .or_default()
            .push(SubMenuItemResponse { id, name, sort });
    }

    // Step 4：组装树
    let result = first_level
        .into_iter()
        .map(|(id, name, sort)| MenuItemResponse {
            id,
            name,
            sort,
            children: children_map.remove(&id).unwrap_or_default(),
        })
        .collect();

    Ok(result)
}

/// 查询单个菜单项的名称（用于 gather 列表组装）
pub async fn get_menu_names(
    pool: &PgPool,
    ids: &[i64],
) -> AppResult<HashMap<i64, String>> {
    if ids.is_empty() {
        return Ok(HashMap::new());
    }
    let rows: Vec<(i64, String)> = sqlx::query_as(
        "SELECT id, name FROM menus WHERE id = ANY($1)",
    )
    .bind(ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    Ok(rows.into_iter().collect())
}
