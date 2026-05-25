import 'dart:convert' show utf8;
import 'dart:io' show File, Platform;

import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import '../data/models/progress_model.dart';
import '../data/models/verb_model.dart';

// Asset files that seed verb data. When any of these change between app
// versions the DB is re-seeded automatically, even if the SQLite schema
// version has not changed.
const _seededAssets = [
  'assets/database/data.sql',
  'assets/database/descriptions.sql',
  'assets/database/example_translations_uk.sql',
  'assets/database/links.sql',
  'assets/database/descriptions_verbformen.sql',
];

/// Simple djb2 hash — fast, no crypto dependency needed.
int _djb2(String s) {
  var h = 5381;
  for (final c in utf8.encode(s)) {
    h = ((h << 5) + h + c) & 0xFFFFFFFF;
  }
  return h;
}

class DatabaseService {
  Database? _db;
  bool _factoryInitialized = false;

  Future<void> init() async {
    _ensureDesktopDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'deutsche_verb.db');

    // Guard against a zero-byte / corrupt DB left by a previously interrupted
    // onCreate / onUpgrade.  If the file exists but is empty we delete it so
    // that openDatabase triggers onCreate again instead of silently hanging.
    final file = File(fullPath);
    if (await file.exists() && await file.length() == 0) {
      await file.delete();
    }

    _db = await openDatabase(
      p.join(dbPath, 'deutsche_verb.db'),
      version: 12,
      onCreate: (db, _) async {
        final schema = await rootBundle.loadString('assets/database/schema.sql');
        for (final stmt in schema.split(';')) {
          final trimmed = stmt.trim();
          if (trimmed.isNotEmpty) {
            await db.execute(trimmed);
          }
        }

        final data = await rootBundle.loadString('assets/database/data.sql');
        await db.transaction((txn) async {
          await _executeSqlFile(txn, data);
        });

        await db.insert('meta', {'key': 'seeded', 'value': '10'});

        final desc = await rootBundle.loadString('assets/database/descriptions.sql');
        await db.transaction((txn) async {
          await _executeSqlFile(txn, desc, originalPrefix: null);
        });

        final uke = await rootBundle.loadString('assets/database/example_translations_uk.sql');
        await db.transaction((txn) async {
          await _executeSqlFile(txn, uke, originalPrefix: null);
        });

        final links = await rootBundle.loadString('assets/database/links.sql');
        await db.transaction((txn) async {
          await _executeSqlFile(txn, links, originalPrefix: null);
        });

        final vfDesc = await rootBundle.loadString('assets/database/descriptions_verbformen.sql');
        final vfDescTransformed = vfDesc
            .replaceAll('SET description =', 'SET description_verbformen =')
            .replaceAll(', description_uk =', ', description_verbformen_uk =');
        await db.transaction((txn) async {
          await _executeSqlFile(txn, vfDescTransformed, originalPrefix: null);
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.dropTableIfExists('progress');
          await db.dropTableIfExists('verbs');
          await db.dropTableIfExists('meta');
          final schema = await rootBundle.loadString('assets/database/schema.sql');
          for (final stmt in schema.split(';')) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              await db.execute(trimmed);
            }
          }
          final data = await rootBundle.loadString('assets/database/data.sql');
          await db.transaction((txn) async {
            // data.sql seeds with "INSERT OR IGNORE INTO"; old upgrade paths
            // used "INSERT OR REPLACE INTO" so use replacementPrefix when
            // re-inserting during an upgrade.
            await _executeSqlFile(
              txn,
              data,
              originalPrefix: 'INSERT OR IGNORE INTO',
              replacementPrefix: 'INSERT OR REPLACE INTO',
            );
          });
          await db.insert('meta', {'key': 'seeded', 'value': '2'});
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN translation_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final data = await rootBundle.loadString('assets/database/data.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(
              txn,
              data,
              originalPrefix: 'INSERT OR IGNORE INTO',
              replacementPrefix: 'INSERT OR REPLACE INTO',
            );
          });
        }
        if (oldVersion < 4) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          await db.transaction((txn) async {
            // descriptions.sql uses UPDATE verbs SET … statements — no prefix
            // replacement needed; the file is flat and already correct for
            // both fresh seed and upgrade paths.
            await _executeSqlFile(txn, desc, originalPrefix: null);
          });
        }
        if (oldVersion < 5) {
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, desc, originalPrefix: null);
          });
        }
        if (oldVersion < 6) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN example_translation_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final uke = await rootBundle.loadString('assets/database/example_translations_uk.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, uke, originalPrefix: null);
          });
        }
        if (oldVersion < 7) {
          final data = await rootBundle.loadString('assets/database/data.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(
              txn,
              data,
              originalPrefix: 'INSERT OR IGNORE INTO',
              replacementPrefix: 'INSERT OR REPLACE INTO',
            );
          });
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, desc, originalPrefix: null);
          });
          final uke = await rootBundle.loadString('assets/database/example_translations_uk.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, uke, originalPrefix: null);
          });
          await db.insert('meta', {'key': 'seeded', 'value': '7'}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (oldVersion < 8) {
          // Re-apply data.sql (fixes broken semicolons splitting INSERT blocks)
          // and descriptions.sql (fixes quadruple-escaped apostrophes).
          final data = await rootBundle.loadString('assets/database/data.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(
              txn,
              data,
              originalPrefix: 'INSERT OR IGNORE INTO',
              replacementPrefix: 'INSERT OR REPLACE INTO',
            );
          });
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, desc, originalPrefix: null);
          });
          await db.insert('meta', {'key': 'seeded', 'value': '8'}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        if (oldVersion < 9) {
          // Upgrade path: re-apply all seeded assets so any user who had a
          // broken DB (missing sqflite import, bad apostrophes, split INSERTs)
          // gets clean data without having to reinstall.
          await _reseedAllAssets(db);
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS verb_links (
              verb_id INTEGER PRIMARY KEY,
              infinitive TEXT NOT NULL,
              url TEXT NOT NULL,
              FOREIGN KEY (verb_id) REFERENCES verbs(id)
            )
          ''');
          final links = await rootBundle.loadString('assets/database/links.sql');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, links, originalPrefix: null);
          });
        }
        if (oldVersion < 11) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description_verbformen TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description_verbformen_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final vfDesc = await rootBundle.loadString('assets/database/descriptions_verbformen.sql');
          final vfDescTransformed = vfDesc
              .replaceAll('SET description =', 'SET description_verbformen =')
              .replaceAll(', description_uk =', ', description_verbformen_uk =');
          await db.transaction((txn) async {
            await _executeSqlFile(txn, vfDescTransformed, originalPrefix: null);
          });
        }
        if (oldVersion < 12) {
          try {
            await db.execute("ALTER TABLE progress ADD COLUMN marked_for_repeat INTEGER NOT NULL DEFAULT 0");
          } catch (_) {}
        }
      },
    );

    // After every open (including upgrades), check whether the bundled asset
    // files have changed since the last seed.  If they have, re-apply them.
    // This makes future data-only fixes deploy automatically without needing
    // a schema version bump.
    await _checkAndReseedIfNeeded(_db!);
  }

  /// Computes a combined hash of all seeded asset files and compares it with
  /// the value stored in the `meta` table.  Re-seeds if they differ.
  Future<void> _checkAndReseedIfNeeded(Database db) async {
    // Build a single hash string from all asset contents.
    final buffer = StringBuffer();
    for (final asset in _seededAssets) {
      final content = await rootBundle.loadString(asset);
      buffer.write(_djb2(content).toRadixString(16));
      buffer.write(':');
    }
    final currentHash = buffer.toString();

    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['asset_hash']);
    final storedHash = rows.isNotEmpty ? rows.first['value'] as String? : null;

    if (storedHash == currentHash) return; // nothing changed

    // Assets changed — re-apply all of them.
    await _reseedAllAssets(db);
    await db.insert(
      'meta',
      {'key': 'asset_hash', 'value': currentHash},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Re-applies all seeded asset files (data, descriptions, example translations).
  static Future<void> _reseedAllAssets(Database db) async {
    // Remove duplicate verbs — keep the row with the lowest id for each
    // infinitive.  This cleans up any duplicates that were inserted by
    // earlier buggy versions of data.sql.
    await db.execute('''
      DELETE FROM verbs
      WHERE id NOT IN (
        SELECT MIN(id) FROM verbs GROUP BY infinitive
      )
    ''');

    final data = await rootBundle.loadString('assets/database/data.sql');
    await db.transaction((txn) async {
      await _executeSqlFile(
        txn,
        data,
        originalPrefix: 'INSERT OR IGNORE INTO',
        replacementPrefix: 'INSERT OR REPLACE INTO',
      );
    });
    final desc = await rootBundle.loadString('assets/database/descriptions.sql');
    await db.transaction((txn) async {
      await _executeSqlFile(txn, desc, originalPrefix: null);
    });
    final uke = await rootBundle.loadString('assets/database/example_translations_uk.sql');
    await db.transaction((txn) async {
      await _executeSqlFile(txn, uke, originalPrefix: null);
    });
    final links = await rootBundle.loadString('assets/database/links.sql');
    await db.transaction((txn) async {
      await _executeSqlFile(txn, links, originalPrefix: null);
    });
    final vfDesc = await rootBundle.loadString('assets/database/descriptions_verbformen.sql');
    final vfDescTransformed = vfDesc
        .replaceAll('SET description =', 'SET description_verbformen =')
        .replaceAll(', description_uk =', ', description_verbformen_uk =');
    await db.transaction((txn) async {
      await _executeSqlFile(txn, vfDescTransformed, originalPrefix: null);
    });
  }

  void _ensureDesktopDatabaseFactory() {
    if (_factoryInitialized) return;

    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryInitialized = true;
  }

  Database get db {
    if (_db == null) throw StateError('Database not initialized. Call init() first.');
    return _db!;
  }

  Future<List<VerbModel>> getVerbs() async {
    final rows = await db.rawQuery('''
      SELECT v.*, l.url AS verbformen_url
      FROM verbs v
      LEFT JOIN verb_links l ON l.verb_id = v.id
      ORDER BY v.infinitive ASC
    ''');
    return rows.map((row) => VerbModel.fromDb(row)).toList();
  }

  Future<void> saveProgress(ProgressModel progress) async {
    await db.insert(
      'progress',
      {
        'verb_id': progress.verbId,
        'status': progress.status,
        'repetitions': progress.repetitions,
        'last_reviewed': progress.lastReviewed,
        'marked_for_repeat': progress.markedForRepeat ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<int, ({String status, bool markedForRepeat})>> getProgressMap() async {
    final rows = await db.query('progress');
    return {
      for (final row in rows)
        row['verb_id'] as int: (
          status: row['status'] as String,
          markedForRepeat: (row['marked_for_repeat'] as int?) == 1,
        ),
    };
  }

  Future<String?> getMeta(String key) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  Future<void> setMeta(String key, String value) async {
    await db.insert('meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearProgress() async {
    await db.delete('progress');
  }

  Future<void> clear() async {
    await db.delete('progress');
    await db.delete('verbs');
    await db.delete('meta');
  }

  /// Splits a SQL file into individual statements and executes each one.
  ///
  /// Uses a character-level state machine to find `;` that are outside
  /// single-quoted string literals — the only correct way to split SQL that
  /// contains multi-line string values (like descriptions.sql) or batch
  /// INSERT blocks (like data.sql).
  ///
  /// Rules:
  ///  • `'...'`  — single-quoted string; `''` inside is an escaped quote
  ///  • `/* .. */` — block comment; skipped entirely
  ///  • `--...`  — line comment; ignored until end of line
  ///  • `;`      — statement terminator (only outside strings/comments)
  ///
  /// Optional [originalPrefix] / [replacementPrefix] let the same file serve
  /// both "initial seed" (`INSERT OR IGNORE INTO`) and "upgrade"
  /// (`INSERT OR REPLACE INTO`) roles.
  static Future<void> _executeSqlFile(
    DatabaseExecutor db,
    String content, {
    String? originalPrefix,
    String replacementPrefix = '',
  }) async {
    final statements = _splitSql(content);
    for (final raw in statements) {
      final sql = raw.trim();
      if (sql.isEmpty || sql.startsWith('--')) continue;
      final finalSql = _applyPrefix(sql, originalPrefix, replacementPrefix);
      try {
        await db.execute(finalSql);
      } catch (e) {
        final preview =
            finalSql.length > 400 ? '${finalSql.substring(0, 400)}…' : finalSql;
        throw Exception('SQL failed: $e\n\nStatement preview:\n$preview');
      }
    }
  }

  /// Character-level SQL splitter: returns statements separated by `;`
  /// that appear outside string literals, block comments and line comments.
  ///
  /// Correctly handles:
  ///  - `'first' || 'second'` with `''` as escaped quote
  ///  - `/* multi-line block comment */`
  ///  - `-- line comment`
  static List<String> _splitSql(String content) {
    // Strip an optional UTF-8 BOM that some generators prepend to asset files.
    content = content.replaceFirst('\ufeff', '');

    final result = <String>[];
    final buf = StringBuffer();
    var inString = false;
    var inBlockComment = false;
    var inLineComment = false;
    var i = 0;

    final len = content.length;
    while (i < len) {
      final ch = content[i];

      if (inLineComment) {
        if (ch == '\n') inLineComment = false;
        i++;
        continue;
      }

      if (inBlockComment) {
        if (ch == '*' && i + 1 < len && content[i + 1] == '/') {
          inBlockComment = false;
          i += 2;
          continue;
        }
        i++;
        continue;
      }

      if (inString) {
        buf.write(ch);
        if (ch == "'") {
          if (i + 1 < len && content[i + 1] == "'") {
            buf.write(content[i + 1]);
            i += 2;
            continue;
          }
          inString = false;
        }
        i++;
        continue;
      }

      // Outside string and comment — check for tokens
      if (ch == '-' && i + 1 < len && content[i + 1] == '-') {
        inLineComment = true;
        i += 2;
        continue;
      }

      if (ch == '/' && i + 1 < len && content[i + 1] == '*') {
        inBlockComment = true;
        i += 2;
        continue;
      }

      if (ch == "'") {
        inString = true;
        buf.write(ch);
        i++;
        continue;
      }

      if (ch == ';') {
        final stmt = buf.toString().trim();
        if (stmt.isNotEmpty) result.add(stmt);
        buf.clear();
        i++;
        continue;
      }

      buf.write(ch);
      i++;
    }

    // Trailing statement without a trailing semicolon
    {
      final last = buf.toString().trim();
      if (last.isNotEmpty) result.add(last);
    }

    return result;
  }
  static String _applyPrefix(
    String stmt,
    String? originalPrefix,
    String replacementPrefix,
  ) {
    if (originalPrefix == null) return stmt;
    return stmt.replaceFirst(originalPrefix, replacementPrefix);
  }
}

extension _DropTable on Database {
  Future<void> dropTableIfExists(String name) async {
    await execute('DROP TABLE IF EXISTS $name');
  }
}