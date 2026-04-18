-- ── 通用多级菜单表 ────────────────────────────────────────────────────────────
CREATE TABLE menus (
    id         BIGSERIAL PRIMARY KEY,
    parent_id  BIGINT REFERENCES menus(id) ON DELETE CASCADE,
    name       VARCHAR(20) NOT NULL,
    type       SMALLINT NOT NULL DEFAULT 1,   -- 1=搭子 2=集市 3=圈子 ...
    sort       INT NOT NULL DEFAULT 0,
    icon_url   VARCHAR(500),
    status     SMALLINT NOT NULL DEFAULT 1,   -- 1=启用 0=禁用
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_menus_parent_id    ON menus(parent_id);
CREATE INDEX idx_menus_type_status  ON menus(type, status);

-- ── 用户菜单兴趣标签 ──────────────────────────────────────────────────────────
CREATE TABLE user_menu_tag (
    id         BIGSERIAL PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    menu_id    BIGINT NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    weight     INT NOT NULL DEFAULT 0,        -- 参与权重（越多越高）
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, menu_id)
);

CREATE INDEX idx_user_menu_tag_user ON user_menu_tag(user_id);
CREATE INDEX idx_user_menu_tag_menu ON user_menu_tag(menu_id);

-- ── 搭子菜单初始数据 (type=1) ─────────────────────────────────────────────────
-- 一级菜单
INSERT INTO menus (id, parent_id, name, type, sort) VALUES
  (1, NULL, '生活', 1, 1),
  (2, NULL, '学习', 1, 2),
  (3, NULL, '兴趣', 1, 3),
  (4, NULL, '游戏', 1, 4);

-- 生活 二级
INSERT INTO menus (id, parent_id, name, type, sort) VALUES
  (10, 1, '饭',   1, 1),
  (11, 1, '探店', 1, 2),
  (12, 1, '遛宠', 1, 3),
  (13, 1, '旅行', 1, 4),
  (14, 1, '电影', 1, 5);

-- 学习 二级
INSERT INTO menus (id, parent_id, name, type, sort) VALUES
  (20, 2, '自习', 1, 1),
  (21, 2, '考证', 1, 2),
  (22, 2, '读书', 1, 3),
  (23, 2, '语言', 1, 4);

-- 兴趣 二级
INSERT INTO menus (id, parent_id, name, type, sort) VALUES
  (30, 3, '篮球',   1, 1),
  (31, 3, '羽毛球', 1, 2),
  (32, 3, '健身',   1, 3),
  (33, 3, '跑步',   1, 4),
  (34, 3, '爬山',   1, 5),
  (35, 3, '摄影',   1, 6);

-- 游戏 二级
INSERT INTO menus (id, parent_id, name, type, sort) VALUES
  (40, 4, '桌游',   1, 1),
  (41, 4, '电竞',   1, 2),
  (42, 4, '密室',   1, 3),
  (43, 4, '剧本杀', 1, 4);

-- 重置序列，避免后续 INSERT 冲突
SELECT setval('menus_id_seq', 100);
