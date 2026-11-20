BEGIN;
ALTER TABLE story_reads ADD COLUMN IF NOT EXISTS completed_at BIGINT;
UPDATE story_reads SET completed_at = read_at WHERE completed_at IS NULL;
CREATE INDEX IF NOT EXISTS ix_story_reads_user_completed ON story_reads(user_id, completed_at);
INSERT INTO schema_migrations(name, applied_at)
VALUES('storybook-upgrade-005', (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT)
ON CONFLICT(name) DO NOTHING;
COMMIT;
