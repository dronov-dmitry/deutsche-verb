import 'package:flutter/material.dart';

import '../data/local/local_cache.dart';
import '../data/models/verb_model.dart';
import '../repositories/verb_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    required VerbRepository verbRepository,
    required LocalCache localCache,
  })  : _verbRepository = verbRepository,
        _localCache = localCache;

  final VerbRepository _verbRepository;
  final LocalCache _localCache;

  bool isBootstrapping = true;
  String levelFilter = 'All';
  String searchQuery = '';
  List<VerbModel> verbs = [];

  List<VerbModel> get visibleVerbs {
    final query = searchQuery.toLowerCase();
    return verbs.where((verb) {
      final matchesLevel = levelFilter == 'All' || verb.level == levelFilter;
      final matchesQuery = query.isEmpty ||
          verb.infinitive.toLowerCase().contains(query) ||
          verb.translation.toLowerCase().contains(query);
      return matchesLevel && matchesQuery;
    }).toList();
  }

  Map<String, int> get learnedByLevel {
    final result = {for (final level in ['A1', 'A2', 'B1', 'B2']) level: 0};
    for (final verb in verbs.where((verb) => verb.progressStatus == 'learned')) {
      result[verb.level] = (result[verb.level] ?? 0) + 1;
    }
    return result;
  }

  int get totalLearned => verbs.where((v) => v.progressStatus == 'learned').length;
  int get totalVerbs => verbs.length;

  Future<void> bootstrap() async {
    await _verbRepository.loadVerbs();
    verbs = _verbRepository.getCachedVerbs();
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> markVerb(VerbModel verb, String status) async {
    verbs = verbs
        .map(
          (item) => item.id == verb.id
              ? item.copyWith(
                  progressStatus: status,
                  repetitions: item.repetitions + 1,
                  lastReviewed: DateTime.now().toUtc().toIso8601String(),
                )
              : item,
        )
        .toList();
    notifyListeners();

    await _verbRepository.saveProgress(verb, status);
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setLevelFilter(String value) {
    levelFilter = value;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _localCache.clearProgress();
    verbs = verbs
        .map((v) => v.copyWith(
              progressStatus: 'learning',
              repetitions: 0,
              lastReviewed: null,
            ))
        .toList();
    notifyListeners();
  }
}
