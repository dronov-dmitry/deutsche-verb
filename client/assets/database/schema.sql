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
  description TEXT NOT NULL DEFAULT '',
  description_uk TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS progress (
  verb_id INTEGER PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'learning',
  repetitions INTEGER NOT NULL DEFAULT 0,
  last_reviewed TEXT
);

CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT
);
