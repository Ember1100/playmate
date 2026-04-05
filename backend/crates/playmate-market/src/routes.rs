//! 集市模块路由注册

use axum::{
    routing::{get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler::{barter, collect, lost_found, part_time, second_hand};

pub fn market_routes() -> Router<AppState> {
    Router::new()
        // 失物招领
        .route("/lost-found",             get(lost_found::list).post(lost_found::create))
        .route("/lost-found/:id",         get(lost_found::get_one).put(lost_found::update).delete(lost_found::delete))
        .route("/lost-found/:id/resolve", post(lost_found::resolve))
        // 二手闲置
        .route("/second-hand",            get(second_hand::list).post(second_hand::create))
        .route("/second-hand/:id",        get(second_hand::get_one).put(second_hand::update).delete(second_hand::delete))
        .route("/second-hand/:id/sold",   post(second_hand::sold))
        // 兼职啦
        .route("/part-time",              get(part_time::list).post(part_time::create))
        .route("/part-time/:id",          get(part_time::get_one).put(part_time::update).delete(part_time::delete))
        // 以物换物
        .route("/barter",                 get(barter::list).post(barter::create))
        .route("/barter/:id",             get(barter::get_one).put(barter::update).delete(barter::delete))
        // 收藏
        .route("/collect",                post(collect::add_collect).delete(collect::remove_collect))
        .route("/collect/mine",           get(collect::list_mine))
}
