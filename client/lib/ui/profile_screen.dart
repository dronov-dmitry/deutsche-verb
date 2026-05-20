import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.learnedByLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Deutsche Verb', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${state.totalLearned} / ${state.totalVerbs} глаголов изучено'),
          const SizedBox(height: 24),
          Text('Изучено по уровням', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in stats.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              trailing: Text(entry.value.toString()),
            ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Тёмная тема'),
            value: state.themeMode == ThemeMode.dark,
            onChanged: (value) {
              state.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Сбросить прогресс'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text('Весь прогресс изучения будет удален.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().resetProgress();
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
