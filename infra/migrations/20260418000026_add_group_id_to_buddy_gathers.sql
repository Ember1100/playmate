-- 搭子局绑定群聊
ALTER TABLE buddy_gathers ADD COLUMN group_id UUID REFERENCES social_groups(id) ON DELETE SET NULL;

-- 群成员最后阅读时间（用于未读计数）
ALTER TABLE social_group_members ADD COLUMN last_read_at TIMESTAMPTZ;
