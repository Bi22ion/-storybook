BEGIN;
ALTER TABLE story_reads ADD COLUMN completed_at INTEGER;
UPDATE story_reads SET completed_at = read_at WHERE completed_at IS NULL;
CREATE INDEX IF NOT EXISTS ix_story_reads_user_completed ON story_reads(user_id, completed_at);
INSERT OR IGNORE INTO schema_migrations(name, applied_at)
VALUES('storybook-upgrade-005', strftime('%s', 'now') * 1000);
COMMIT;
