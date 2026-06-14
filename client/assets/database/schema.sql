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

CREATE TABLE IF NOT EXISTS verbs (
  id INTEGER PRIMARY KEY,
  infinitive TEXT NOT NULL UNIQUE,
  translation TEXT NOT NULL,
  translation_uk TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL,
  past_participle TEXT NOT NULL,
  preterite TEXT NOT NULL,
  auxiliary_verb TEXT NOT NULL,
  level TEXT NOT NULL,
  example_sentence TEXT NOT NULL,
  example_translation TEXT NOT NULL,
  example_translation_uk TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  description_uk TEXT NOT NULL DEFAULT '',
  description_verbformen TEXT NOT NULL DEFAULT '',
  description_verbformen_uk TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS progress (
  verb_id INTEGER PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'learning',
  repetitions INTEGER NOT NULL DEFAULT 0,
  last_reviewed TEXT,
  marked_for_repeat INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS verb_links (
  verb_id INTEGER PRIMARY KEY,
  infinitive TEXT NOT NULL,
  url TEXT NOT NULL,
  FOREIGN KEY (verb_id) REFERENCES verbs(id)
);

CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT
);
