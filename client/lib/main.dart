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

// Entry point: initialises database, pre-fetches updates, bootstraps app state.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:provider/provider.dart';

import 'data/local/local_cache.dart';
import 'providers/app_state.dart';
import 'repositories/verb_repository.dart';
import 'services/database_service.dart';
import 'services/github_update_service.dart';
import 'ui/error_screen.dart';
import 'ui/home_shell.dart';
import 'ui/update_dialog.dart';

void _showError(Object error, StackTrace stack, UpdateInfo? update) {
  // ignore: avoid_print
  print('[FATAL] $error\n$stack');
  runApp(ErrorApp(error: error, stack: stack, preFetchedUpdate: update));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _showError(error, stack, null);
    return true;
  };

  UpdateInfo? preFetchedUpdate;
  try {
    preFetchedUpdate = await GithubUpdateService.prefetchUpdate();
  } catch (_) {}

  try {
    final databaseService = DatabaseService();
    await databaseService.init().timeout(
      const Duration(seconds: 120),
      onTimeout: () => throw Exception('Database init timed out'),
    );

    final localCache = LocalCache(databaseService);
    await localCache.loadVerbs();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(
              verbRepository: VerbRepository(localCache),
              localCache: localCache,
              preFetchedUpdate: preFetchedUpdate,
            )..bootstrap(),
          ),
        ],
        child: const DeutscheVerbApp(),
      ),
    );
  } catch (e, stack) {
    _showError(e, stack, preFetchedUpdate);
  }
}

class DeutscheVerbApp extends StatelessWidget {
  const DeutscheVerbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Deutsche Verb',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D), brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: state.themeMode,
          home: state.isBootstrapping
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : const UpdateGate(child: HomeShell()),
        );
      },
    );
  }
}
