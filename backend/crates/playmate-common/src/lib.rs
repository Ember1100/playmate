//! playmate-common — 共享基础设施

pub mod auth;
pub mod cache;
pub mod config;
pub mod db;
pub mod error;
pub mod hub;
pub mod response;
pub mod state;
pub mod storage;

pub use auth::CurrentUser;
pub use error::{AppError, AppResult};
pub use hub::ConnectionHub;
pub use response::ApiResponse;
pub use state::AppState;
pub use storage::StorageService;
