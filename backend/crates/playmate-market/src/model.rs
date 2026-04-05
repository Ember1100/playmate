//! 集市模块数据模型

use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde_json::Value;
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct LostFound {
    pub id:          Uuid,
    pub user_id:     Uuid,
    #[sqlx(rename = "type")]
    pub item_type:   i16,         // 1=失物 2=招领
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,         // 1=发布中 2=已找到
    pub serial_no:   String,
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct SecondHand {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub price:       Decimal,
    pub category:    Option<String>,
    pub condition:   i16,         // 1=全新 2=几乎全新 3=中等 4=有磨损
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,         // 1=在售 2=已售出
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct PartTime {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub salary:      Option<String>,
    pub salary_type: Option<i16>,  // 1=时薪 2=日薪 3=月薪
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,          // 1=招募中 2=已结束
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct Barter {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub offer_item:  String,
    pub want_item:   String,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,          // 1=换物中 2=已完成
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}
