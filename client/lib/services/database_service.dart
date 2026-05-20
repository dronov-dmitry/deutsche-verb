import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../data/models/progress_model.dart';
import '../data/models/verb_model.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'deutsche_verb.db'),
      version: 1,
      onCreate: (db, _) async {
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

        await db.insert('meta', {'key': 'seeded', 'value': '1'});
      },
    );
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

  Future<void> clearProgress() async {
    await db.delete('progress');
  }

  Future<void> clear() async {
    await db.delete('progress');
    await db.delete('verbs');
    await db.delete('meta');
  }
}
