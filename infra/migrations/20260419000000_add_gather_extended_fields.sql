-- 搭子局扩展字段：地标、行程、截止时间、费用、年龄、性别偏好、封面、参与控制
ALTER TABLE buddy_gathers
    ADD COLUMN IF NOT EXISTS landmark          VARCHAR(200),
    ADD COLUMN IF NOT EXISTS schedule          TEXT,
    ADD COLUMN IF NOT EXISTS deadline          TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS fee_type          SMALLINT         NOT NULL DEFAULT 0,   -- 0=免费 1=按需付费 2=AA制
    ADD COLUMN IF NOT EXISTS fee_amount        DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS age_min           SMALLINT         NOT NULL DEFAULT 18,
    ADD COLUMN IF NOT EXISTS age_max           SMALLINT         NOT NULL DEFAULT 35,
    ADD COLUMN IF NOT EXISTS gender_pref       SMALLINT         NOT NULL DEFAULT 0,   -- 0=不限 1=仅男 2=仅女
    ADD COLUMN IF NOT EXISTS cover_url         VARCHAR(500),
    ADD COLUMN IF NOT EXISTS require_real_name BOOLEAN          NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS require_review    BOOLEAN          NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS allow_transfer    BOOLEAN          NOT NULL DEFAULT false;
