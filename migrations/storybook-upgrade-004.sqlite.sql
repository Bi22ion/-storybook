ALTER TABLE story_reads ADD COLUMN completed_at INTEGER;
CREATE TABLE IF NOT EXISTS attempt_question_marks(
  attempt_id INTEGER NOT NULL REFERENCES attempts(id) ON DELETE CASCADE,
  question_index INTEGER NOT NULL CHECK(question_index >= 0),
  final_mark INTEGER NOT NULL CHECK(final_mark >= 0),
  feedback TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY(attempt_id,question_index)
);
