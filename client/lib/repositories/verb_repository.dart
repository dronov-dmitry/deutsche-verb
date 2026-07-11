// Copyright (C) 2024 Dmitry Dronov
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
