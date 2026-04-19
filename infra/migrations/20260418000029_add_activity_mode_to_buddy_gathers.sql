-- 搭子局新增活动方式字段：offline=线下，online=线上
ALTER TABLE buddy_gathers
    ADD COLUMN IF NOT EXISTS activity_mode VARCHAR(10) NOT NULL DEFAULT 'offline';
