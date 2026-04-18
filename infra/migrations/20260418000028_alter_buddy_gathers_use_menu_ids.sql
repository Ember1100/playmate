-- 替换 buddy_gathers 的 category / theme 为菜单 ID 外键
ALTER TABLE buddy_gathers DROP COLUMN IF EXISTS category;
ALTER TABLE buddy_gathers DROP COLUMN IF EXISTS theme;

ALTER TABLE buddy_gathers
    ADD COLUMN first_menu_id  BIGINT REFERENCES menus(id),
    ADD COLUMN second_menu_id BIGINT REFERENCES menus(id);

CREATE INDEX idx_buddy_gathers_first_menu  ON buddy_gathers(first_menu_id);
CREATE INDEX idx_buddy_gathers_second_menu ON buddy_gathers(second_menu_id);
