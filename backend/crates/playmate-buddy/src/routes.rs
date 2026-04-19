//! 搭子模块路由注册

use axum::{
    routing::{get, post, put},
    Router,
};

use playmate_common::AppState;

use crate::handler::{buddy, career, gather, invitation, match_handler, menu, search};

pub fn buddy_routes() -> Router<AppState> {
    Router::new()
        // 线上快速匹配
        .route("/match/join",    post(match_handler::join_match))
        .route("/match/leave",   axum::routing::delete(match_handler::leave_match))
        .route("/match/result",  get(match_handler::get_match_result))
        .route("/match/next",    post(match_handler::next_match))
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
        // 搜索
        .route("/search",                  get(search::search_buddy))
        // 菜单
        .route("/menus",                   get(menu::list_menus))
        // 搭子局
        .route("/gathers",                 post(gather::create_gather).get(gather::list_gathers))
        .route("/gathers/:id",             get(gather::get_gather))
        .route("/gathers/:id/join",        post(gather::join_gather))
        .route("/gathers/:id/leave",       post(gather::leave_gather))
        .route("/gathers/:id/cancel",      post(gather::cancel_gather))
}
