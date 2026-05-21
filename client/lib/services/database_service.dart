import 'dart:io' show File, Platform;

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import '../data/models/progress_model.dart';
import '../data/models/verb_model.dart';

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
      version: 5,
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
          for (final stmt in data.split(';')) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              await txn.execute(trimmed);
            }
          }
        });

        await db.insert('meta', {'key': 'seeded', 'value': '3'});

        final desc = await rootBundle.loadString('assets/database/descriptions.sql');
        for (final stmt in desc.split(';')) {
          final trimmed = stmt.trim();
          if (trimmed.isNotEmpty) {
            await db.execute(trimmed);
          }
        }
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
          for (final stmt in data.split(';')) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              await db.execute(trimmed);
            }
          }
          await db.insert('meta', {'key': 'seeded', 'value': '2'});
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN translation_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final data = await rootBundle.loadString('assets/database/data.sql');
          for (final stmt in data.split(';')) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              await db.execute(trimmed);
            }
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE verbs ADD COLUMN description_uk TEXT NOT NULL DEFAULT ''");
          } catch (_) {}
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          for (final stmt in desc.split(';')) {
            final trimmed = stmt.trim();
            if (trimmed.isNotEmpty) {
              await db.execute(trimmed);
            }
          }
        }
        if (oldVersion < 5) {
          // Re-apply descriptions to fix missing or corrupted data.
          final desc = await rootBundle.loadString('assets/database/descriptions.sql');
          await db.transaction((txn) async {
            for (final stmt in desc.split(';')) {
              final trimmed = stmt.trim();
              if (trimmed.isNotEmpty) {
                await txn.execute(trimmed);
              }
            }
          });
        }
      },
    );
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
    final rows = await db.query('verbs', orderBy: 'infinitive ASC');
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<int, String>> getProgressMap() async {
    final rows = await db.query('progress');
    return {for (final row in rows) row['verb_id'] as int: row['status'] as String};
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
}

extension _DropTable on Database {
  Future<void> dropTableIfExists(String name) async {
    await execute('DROP TABLE IF EXISTS $name');
  }
}
