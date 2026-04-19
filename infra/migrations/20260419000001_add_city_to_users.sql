ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(50);

-- Backfill from questionnaire for existing users
UPDATE users u
SET city = q.city
FROM user_questionnaire q
WHERE q.user_id = u.id AND q.city IS NOT NULL AND u.city IS NULL;
