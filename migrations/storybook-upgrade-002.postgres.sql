BEGIN;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS learning_area TEXT;
ALTER TABLE stories ADD COLUMN IF NOT EXISTS competence TEXT;

CREATE TABLE IF NOT EXISTS attempt_question_marks (
  attempt_id BIGINT NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
  question_index INTEGER NOT NULL CHECK (question_index >= 0),
  teacher_id BIGINT NOT NULL REFERENCES users(id),
  final_mark INTEGER NOT NULL CHECK (final_mark >= 0),
  feedback TEXT NOT NULL DEFAULT '',
  updated_at BIGINT NOT NULL,
  PRIMARY KEY (attempt_id, question_index)
);
INSERT INTO schema_migrations(name,applied_at) VALUES('storybook-upgrade-002',(EXTRACT(EPOCH FROM NOW())*1000)::BIGINT) ON CONFLICT(name) DO NOTHING;
COMMIT;
