import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../strings.dart';
import 'flashcards_screen.dart';
import 'info_screen.dart';
import 'profile_screen.dart';
import 'verb_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppState>().locale;

const screens = [
    VerbListScreen(),
    FlashcardsScreen(),
    ProfileScreen(),
    InfoScreen(),
  ];

  return Scaffold(
    body: screens[_index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: [
        NavigationDestination(icon: const Icon(Icons.list_alt), label: Strings.of('verbs', locale)),
        NavigationDestination(icon: const Icon(Icons.style), label: Strings.of('training', locale)),
        NavigationDestination(icon: const Icon(Icons.person), label: Strings.of('profile', locale)),
        NavigationDestination(icon: const Icon(Icons.info_outline), label: Strings.of('info', locale)),
      ],
    ),
  );
  }
}
