import '../data/local/local_cache.dart';
import '../data/models/progress_model.dart';
import '../data/models/verb_model.dart';
import '../services/database_service.dart';

class VerbRepository {
  VerbRepository(this._localCache, this._db);

  final LocalCache _localCache;
  final DatabaseService _db;

  List<VerbModel> getCachedVerbs() => _localCache.getVerbs();

  Future<void> loadVerbs() => _localCache.loadVerbs();

  Future<void> saveProgress(VerbModel verb, String status) async {
    final progress = ProgressModel(
      verbId: verb.id,
      status: status,
      repetitions: verb.repetitions + 1,
      lastReviewed: DateTime.now().toUtc().toIso8601String(),
    );
    await _localCache.saveProgress(progress);
  }
}
