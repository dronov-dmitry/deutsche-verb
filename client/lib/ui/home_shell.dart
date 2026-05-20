import 'package:flutter/material.dart';

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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Глаголы'),
          NavigationDestination(icon: Icon(Icons.style), label: 'Тренировка'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'Инфо'),
        ],
      ),
    );
  }
}
