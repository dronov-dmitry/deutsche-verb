// Bottom navigation shell switching between verb list, flashcards, profile, info.

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
