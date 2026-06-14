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

// Central app state: verbs, filters, theme, locale, progress, update checks.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/local/local_cache.dart';
import '../data/models/verb_model.dart';
import '../repositories/verb_repository.dart';
import '../services/github_update_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required VerbRepository verbRepository,
    required LocalCache localCache,
    UpdateInfo? preFetchedUpdate,
  })  : _verbRepository = verbRepository,
        _localCache = localCache,
        _preFetchedUpdate = preFetchedUpdate;

  final VerbRepository _verbRepository;
  final LocalCache _localCache;
  final UpdateInfo? _preFetchedUpdate;

  bool isBootstrapping = true;
  String _appVersion = '';
  String get appVersion => _appVersion;
  String levelFilter = 'All';
  String typeFilter = 'All';
  String progressFilter = 'all';
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
      final matchesType = typeFilter == 'All' || verb.type == _mapTypeFilter(typeFilter);
      final matchesProgress = progressFilter == 'all' ||
          (progressFilter == 'learned' && verb.progressStatus == 'learned') ||
          (progressFilter == 'learning' && verb.progressStatus != 'learned');
      final translated = verb.translationFor(locale).toLowerCase();
      final matchesQuery = query.isEmpty ||
          verb.infinitive.toLowerCase().contains(query) ||
          translated.contains(query) ||
          verb.preterite.toLowerCase().contains(query) ||
          verb.pastParticiple.toLowerCase().contains(query);
      return matchesLevel && matchesType && matchesProgress && matchesQuery;
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
    final info = await PackageInfo.fromPlatform();
    _appVersion = info.version;
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

    if (_preFetchedUpdate != null) {
      _pendingUpdate = _preFetchedUpdate;
      notifyListeners();
    }
  }

  Future<void> markVerb(VerbModel verb, String status, {bool? markedForRepeat}) async {
    verbs = verbs
        .map(
          (item) => item.id == verb.id
              ? item.copyWith(
                  progressStatus: status,
                  repetitions: item.repetitions + 1,
                  lastReviewed: DateTime.now().toUtc().toIso8601String(),
                  markedForRepeat: markedForRepeat,
                )
              : item,
        )
        .toList();
    notifyListeners();

    await _verbRepository.saveProgress(verb, status, markedForRepeat: markedForRepeat);
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

  String _mapTypeFilter(String filter) {
    switch (filter) {
      case 'weak':
        return 'regular';
      case 'strong':
        return 'irregular';
      default:
        return filter;
    }
  }

  void setProgressFilter(String value) {
    progressFilter = value;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _localCache.clearProgress();
    verbs = verbs
        .map((v) => v.copyWith(
              progressStatus: 'learning',
              repetitions: 0,
              lastReviewed: null,
              markedForRepeat: false,
            ))
        .toList();
    notifyListeners();
  }
}
