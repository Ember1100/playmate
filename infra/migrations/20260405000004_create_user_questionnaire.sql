CREATE TABLE user_questionnaire (
    user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    identity     VARCHAR(20),
    interests    JSONB DEFAULT '[]',
    purposes     JSONB DEFAULT '[]',
    age_range    VARCHAR(10),
    city         VARCHAR(50),
    personality  JSONB,
    life_goal    TEXT,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
