ALTER TABLE story_reads ADD COLUMN IF NOT EXISTS completed_at BIGINT;
CREATE TABLE IF NOT EXISTS attempt_question_marks(
  attempt_id BIGINT NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
  question_index INTEGER NOT NULL CHECK(question_index >= 0),
  final_mark INTEGER NOT NULL CHECK(final_mark >= 0),
  feedback TEXT,
  updated_at BIGINT NOT NULL,
  PRIMARY KEY(attempt_id,question_index)
);
ALTER TABLE attempt_question_marks ENABLE ROW LEVEL SECURITY;
