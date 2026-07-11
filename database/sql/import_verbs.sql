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

INSERT OR IGNORE INTO verbs (
  infinitive,
  translation,
  type,
  past_participle,
  preterite,
  auxiliary_verb,
  level,
  example_sentence,
  example_translation
) VALUES
  ('machen', 'делать', 'regular', 'gemacht', 'machte', 'haben', 'A1', 'Ich mache meine Hausaufgaben.', 'Я делаю домашнее задание.'),
  ('gehen', 'идти', 'irregular', 'gegangen', 'ging', 'sein', 'A1', 'Wir gehen heute ins Kino.', 'Мы сегодня идем в кино.'),
  ('sehen', 'видеть', 'irregular', 'gesehen', 'sah', 'haben', 'A2', 'Sie sieht den Zug.', 'Она видит поезд.');
