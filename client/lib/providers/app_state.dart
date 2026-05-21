import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/local/local_cache.dart';
import '../data/models/verb_model.dart';
import '../repositories/verb_repository.dart';
import '../services/update_service.dart';

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
  String typeFilter = 'All';
  String searchQuery = '';
  String locale = 'ru';
  List<VerbModel> verbs = [];
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _localCache.setMeta('theme_mode', mode.name);
  }

  Future<void> setLocale(String value) async {
    locale = value;
    notifyListeners();
    await _localCache.setMeta('locale', value);
  }

  List<VerbModel> get visibleVerbs {
    final query = searchQuery.toLowerCase();
    return verbs.where((verb) {
      final matchesLevel = levelFilter == 'All' || verb.level == levelFilter;
      final matchesType = typeFilter == 'All' || verb.type == typeFilter;
      final translated = verb.translationFor(locale).toLowerCase();
      final matchesQuery = query.isEmpty ||
          verb.infinitive.toLowerCase().contains(query) ||
          translated.contains(query);
      return matchesLevel && matchesType && matchesQuery;
    }).toList();
  }

  Map<String, int> get learnedByLevel {
    final result = {for (final level in ['A1', 'A2', 'B1', 'B2', 'C1']) level: 0};
    for (final verb in verbs.where((verb) => verb.progressStatus == 'learned')) {
      result[verb.level] = (result[verb.level] ?? 0) + 1;
    }
    return result;
  }

  int get totalLearned => verbs.where((v) => v.progressStatus == 'learned').length;
  int get totalVerbs => verbs.length;

  UpdateInfo? _pendingUpdate;
  UpdateInfo? get pendingUpdate => _pendingUpdate;

  Future<void> bootstrap() async {
    await _verbRepository.loadVerbs();
    verbs = _verbRepository.getCachedVerbs();
    final savedTheme = await _localCache.getMeta('theme_mode');
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == savedTheme, orElse: () => ThemeMode.system);
    }
    final savedLocale = await _localCache.getMeta('locale');
    if (savedLocale != null && ['ru', 'uk'].contains(savedLocale)) {
      locale = savedLocale;
    }
    isBootstrapping = false;
    notifyListeners();

    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final service = UpdateService(currentVersion: info.version);
      final update = await service.checkForUpdate();
      if (update != null) {
        _pendingUpdate = update;
        notifyListeners();
      }
    } catch (_) {}
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

  void setTypeFilter(String value) {
    typeFilter = value;
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
