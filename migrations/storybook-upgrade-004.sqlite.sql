BEGIN;
CREATE INDEX IF NOT EXISTS ix_class_members_class_role ON class_members(class_id, member_role, user_id);
CREATE INDEX IF NOT EXISTS ix_test_classes_class ON test_classes(class_id, test_id);

INSERT OR IGNORE INTO class_members(class_id, user_id, member_role, created_at)
SELECT c.id, u.id, u.role, CAST(strftime('%s','now') AS INTEGER) * 1000
FROM users u
JOIN classes c ON c.id = (
  SELECT c2.id FROM classes c2
  WHERE instr(',' || COALESCE(u.level, '') || ',', ',' || c2.level || ',') > 0
  ORDER BY c2.academic_year DESC, c2.id DESC LIMIT 1
)
WHERE u.role IN ('teacher', 'student') AND u.status = 'approved';

INSERT OR IGNORE INTO schema_migrations(name, applied_at)
VALUES('storybook-upgrade-004', CAST(strftime('%s','now') AS INTEGER) * 1000);
COMMIT;
