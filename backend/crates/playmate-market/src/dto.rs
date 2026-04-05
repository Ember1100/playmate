//! 集市模块 Request / Response DTO

use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;
use validator::Validate;

use crate::model::{Barter, LostFound, PartTime, SecondHand};

// ── Lost Found ───────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateLostFoundRequest {
    pub item_type: i16, // 1=失物 2=招领
    #[validate(length(min = 1, max = 100))]
    pub title:       String,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct UpdateLostFoundRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       Option<String>,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize)]
pub struct ListLostFoundQuery {
    pub item_type: Option<i16>,
    pub category:  Option<String>,
    pub keyword:   Option<String>,
    #[serde(default = "default_page")]
    pub page:      i64,
    #[serde(default = "default_limit")]
    pub limit:     i64,
}

#[derive(Serialize)]
pub struct LostFoundResponse {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub item_type:   i16,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,
    pub serial_no:   String,
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

impl From<LostFound> for LostFoundResponse {
    fn from(r: LostFound) -> Self {
        Self {
            id:          r.id,
            user_id:     r.user_id,
            item_type:   r.item_type,
            title:       r.title,
            description: r.description,
            images:      r.images,
            category:    r.category,
            location:    r.location,
            contact:     r.contact,
            status:      r.status,
            serial_no:   r.serial_no,
            view_count:  r.view_count,
            created_at:  r.created_at,
        }
    }
}

// ── Second Hand ──────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateSecondHandRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       String,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub price:       Decimal,
    pub category:    Option<String>,
    pub condition:   Option<i16>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct UpdateSecondHandRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       Option<String>,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub price:       Option<Decimal>,
    pub category:    Option<String>,
    pub condition:   Option<i16>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize)]
pub struct ListSecondHandQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Serialize)]
pub struct SecondHandResponse {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub price:       Decimal,
    pub category:    Option<String>,
    pub condition:   i16,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

impl From<SecondHand> for SecondHandResponse {
    fn from(s: SecondHand) -> Self {
        Self {
            id:          s.id,
            user_id:     s.user_id,
            title:       s.title,
            description: s.description,
            images:      s.images,
            price:       s.price,
            category:    s.category,
            condition:   s.condition,
            location:    s.location,
            contact:     s.contact,
            status:      s.status,
            view_count:  s.view_count,
            created_at:  s.created_at,
        }
    }
}

// ── Part Time ────────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreatePartTimeRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       String,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub salary:      Option<String>,
    pub salary_type: Option<i16>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct UpdatePartTimeRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       Option<String>,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    pub salary:      Option<String>,
    pub salary_type: Option<i16>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize)]
pub struct ListPartTimeQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Serialize)]
pub struct PartTimeResponse {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       String,
    pub description: Option<String>,
    pub images:      Value,
    pub salary:      Option<String>,
    pub salary_type: Option<i16>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
    pub status:      i16,
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

impl From<PartTime> for PartTimeResponse {
    fn from(p: PartTime) -> Self {
        Self {
            id:          p.id,
            user_id:     p.user_id,
            title:       p.title,
            description: p.description,
            images:      p.images,
            salary:      p.salary,
            salary_type: p.salary_type,
            category:    p.category,
            location:    p.location,
            contact:     p.contact,
            status:      p.status,
            view_count:  p.view_count,
            created_at:  p.created_at,
        }
    }
}

// ── Barter ───────────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateBarterRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       String,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    #[validate(length(min = 1, max = 100))]
    pub offer_item:  String,
    #[validate(length(min = 1, max = 100))]
    pub want_item:   String,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct UpdateBarterRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       Option<String>,
    pub description: Option<String>,
    pub images:      Option<Vec<String>>,
    #[validate(length(min = 1, max = 100))]
    pub offer_item:  Option<String>,
    #[validate(length(min = 1, max = 100))]
    pub want_item:   Option<String>,
    pub category:    Option<String>,
    pub location:    Option<String>,
    pub contact:     Option<String>,
}

#[derive(Deserialize)]
pub struct ListBarterQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Serialize)]
pub struct BarterResponse {
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
    pub status:      i16,
    pub view_count:  i32,
    pub created_at:  DateTime<Utc>,
}

impl From<Barter> for BarterResponse {
    fn from(b: Barter) -> Self {
        Self {
            id:          b.id,
            user_id:     b.user_id,
            title:       b.title,
            description: b.description,
            images:      b.images,
            offer_item:  b.offer_item,
            want_item:   b.want_item,
            category:    b.category,
            location:    b.location,
            contact:     b.contact,
            status:      b.status,
            view_count:  b.view_count,
            created_at:  b.created_at,
        }
    }
}

// ── Collect ──────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct CollectRequest {
    pub target_type: String, // 'lost_found'|'second_hand'|'part_time'|'barter'
    pub target_id:   Uuid,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }
