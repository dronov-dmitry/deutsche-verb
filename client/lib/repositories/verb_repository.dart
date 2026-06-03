// Repository: delegates verb / progress operations to LocalCache.

import '../data/local/local_cache.dart';
import '../data/models/progress_model.dart';
import '../data/models/verb_model.dart';

class VerbRepository {
  VerbRepository(this._localCache);

  final LocalCache _localCache;

  List<VerbModel> getCachedVerbs() => _localCache.getVerbs();

  Future<void> loadVerbs() => _localCache.loadVerbs();

  Future<void> saveProgress(VerbModel verb, String status, {bool? markedForRepeat}) async {
    final progress = ProgressModel(
      verbId: verb.id,
      status: status,
      repetitions: verb.repetitions + 1,
      lastReviewed: DateTime.now().toUtc().toIso8601String(),
      markedForRepeat: markedForRepeat ?? verb.markedForRepeat,
    );
    await _localCache.saveProgress(progress);
  }
}
