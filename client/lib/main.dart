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
import 'package:provider/provider.dart';

import 'data/local/local_cache.dart';
import 'providers/app_state.dart';
import 'repositories/verb_repository.dart';
import 'services/database_service.dart';
import 'services/app_update.dart';
import 'ui/error_screen.dart';
import 'ui/home_shell.dart';
import 'ui/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UpdateInfo? preFetchedUpdate;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final service = AppUpdate(currentVersion: packageInfo.version);
    preFetchedUpdate = await service.checkForUpdate();
  } catch (_) {}

  try {
    final databaseService = DatabaseService();
    final localCache = LocalCache(databaseService);
    await localCache.init();

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
    runApp(ErrorApp(
      error: e,
      stack: stack,
      preFetchedUpdate: preFetchedUpdate,
    ));
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
