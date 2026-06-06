-- Copyright (C) 2024 Dmitry Dronov
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  google_id TEXT UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS verbs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  infinitive TEXT NOT NULL UNIQUE,
  translation TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('regular', 'irregular')),
  past_participle TEXT NOT NULL,
  preterite TEXT NOT NULL,
  auxiliary_verb TEXT NOT NULL CHECK (auxiliary_verb IN ('haben', 'sein')),
  level TEXT NOT NULL CHECK (level IN ('A1', 'A2', 'B1', 'B2')),
  example_sentence TEXT NOT NULL,
  example_translation TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_progress (
  user_id TEXT NOT NULL,
  verb_id INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('learning', 'learned')),
  repetitions INTEGER NOT NULL DEFAULT 0,
  last_reviewed TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, verb_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (verb_id) REFERENCES verbs(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_verbs_level ON verbs(level);
CREATE INDEX IF NOT EXISTS idx_progress_user_status ON user_progress(user_id, status);
