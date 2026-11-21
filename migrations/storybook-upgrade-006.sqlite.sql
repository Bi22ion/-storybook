BEGIN;
CREATE INDEX IF NOT EXISTS ix_audit_id_desc ON audit(id DESC);
CREATE INDEX IF NOT EXISTS ix_audit_action_id ON audit(action, id DESC);
CREATE INDEX IF NOT EXISTS ix_sessions_user_expiry ON sessions(user_id, expires_at);
INSERT OR IGNORE INTO schema_migrations(name, applied_at)
VALUES('storybook-upgrade-006', strftime('%s', 'now') * 1000);
COMMIT;
