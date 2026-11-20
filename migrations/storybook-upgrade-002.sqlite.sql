PRAGMA foreign_keys=OFF;
BEGIN;
ALTER TABLE stories ADD COLUMN learning_area TEXT;
ALTER TABLE stories ADD COLUMN competence TEXT;

CREATE TABLE IF NOT EXISTS attempt_question_marks (
  attempt_id INTEGER NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
  question_index INTEGER NOT NULL CHECK (question_index >= 0),
  teacher_id INTEGER NOT NULL REFERENCES users(id),
  final_mark INTEGER NOT NULL CHECK (final_mark >= 0),
  feedback TEXT NOT NULL DEFAULT '',
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (attempt_id, question_index)
);
INSERT OR IGNORE INTO schema_migrations(name,applied_at) VALUES('storybook-upgrade-002',strftime('%s','now')*1000);
COMMIT;
PRAGMA foreign_keys=ON;
