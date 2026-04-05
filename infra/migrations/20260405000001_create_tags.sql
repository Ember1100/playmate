CREATE TABLE tags (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(32) NOT NULL UNIQUE,
    category   VARCHAR(32) NOT NULL,
    sort_order INTEGER DEFAULT 0
);

CREATE TABLE user_tags (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tag_id  INTEGER REFERENCES tags(id),
    PRIMARY KEY (user_id, tag_id)
);
