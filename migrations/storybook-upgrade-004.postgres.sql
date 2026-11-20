BEGIN;

CREATE INDEX IF NOT EXISTS ix_class_members_class_role ON class_members(class_id, member_role, user_id);
CREATE INDEX IF NOT EXISTS ix_test_classes_class ON test_classes(class_id, test_id);

-- Preserve legacy level-based rosters by linking each user to the latest matching class.
INSERT INTO class_members(class_id, user_id, member_role, created_at)
SELECT c.id, u.id, u.role, (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
FROM users u
JOIN classes c ON c.id = (
  SELECT c2.id FROM classes c2
  WHERE c2.level = ANY(string_to_array(COALESCE(u.level, ''), ','))
  ORDER BY c2.academic_year DESC, c2.id DESC LIMIT 1
)
WHERE u.role IN ('teacher', 'student') AND u.status = 'approved'
ON CONFLICT(class_id, user_id) DO NOTHING;

INSERT INTO schema_migrations(name, applied_at)
VALUES('storybook-upgrade-004', (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT)
ON CONFLICT(name) DO NOTHING;
COMMIT;
