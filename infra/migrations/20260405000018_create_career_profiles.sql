CREATE TABLE career_profiles (
    user_id     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    job_title   VARCHAR(100),
    company     VARCHAR(100),
    skills      JSONB DEFAULT '[]',
    experience  TEXT,
    looking_for TEXT,
    is_public   BOOLEAN NOT NULL DEFAULT true,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
