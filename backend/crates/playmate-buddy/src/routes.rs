//! 搭子模块路由注册

use axum::{
    routing::{get, post, put},
    Router,
};

use playmate_common::AppState;

use crate::handler::{buddy, career, invitation};

pub fn buddy_routes() -> Router<AppState> {
    Router::new()
        // 搭子推荐与请求
        .route("/candidates",              get(buddy::list_candidates))
        .route("/request",                 post(buddy::send_request))
        .route("/request/:id/respond",     put(buddy::respond_request))
        .route("/mine",                    get(buddy::list_my_buddies))
        // 邀约
        .route("/invitations",             post(invitation::send_invitation))
        .route("/invitations/sent",        get(invitation::list_sent))
        .route("/invitations/received",    get(invitation::list_received))
        .route("/invitations/:id/respond", put(invitation::respond_invitation))
        // 职业搭子阵地
        .route("/career",                  get(career::list_career))
        .route("/career/:user_id",         get(career::get_career))
}
