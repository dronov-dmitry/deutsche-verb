import '../models/progress_model.dart';
import '../models/verb_model.dart';
import '../../services/database_service.dart';

class LocalCache {
  LocalCache(this._db);

  final DatabaseService _db;

  Future<void> init() async {
    await _db.init();
  }

  List<VerbModel> getVerbs() => _verbsCache;

  List<VerbModel> _verbsCache = [];

  Future<void> loadVerbs() async {
    final verbs = await _db.getVerbs();
    final progressMap = await _db.getProgressMap();
    _verbsCache = verbs.map((v) {
      final entry = progressMap[v.id];
      if (entry != null) {
        return v.copyWith(
          progressStatus: entry.status,
          markedForRepeat: entry.markedForRepeat,
        );
      }
      return v;
    }).toList();
  }

  Future<void> saveProgress(ProgressModel progress) async {
    await _db.saveProgress(progress);
  }

  List<ProgressModel> getProgress() {
    return [];
  }

  Future<void> clearProgress() async {
    await _db.clearProgress();
  }

  Future<String?> getMeta(String key) => _db.getMeta(key);

  Future<void> setMeta(String key, String value) => _db.setMeta(key, value);

  Future<void> clear() async {
    await _db.clear();
    _verbsCache = [];
  }
}
