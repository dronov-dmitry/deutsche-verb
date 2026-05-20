import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/local/local_cache.dart';
import 'providers/app_state.dart';
import 'repositories/verb_repository.dart';
import 'services/database_service.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  final localCache = LocalCache(databaseService);
  await localCache.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            verbRepository: VerbRepository(localCache, databaseService),
            localCache: localCache,
          )..bootstrap(),
        ),
      ],
      child: const DeutscheVerbApp(),
    ),
  );
}

class DeutscheVerbApp extends StatelessWidget {
  const DeutscheVerbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deutsche Verb',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D)),
        useMaterial3: true,
      ),
      home: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.isBootstrapping) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const HomeShell();
        },
      ),
    );
  }
}
