import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final loc = state.locale;
    final stats = state.learnedByLevel;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.of('profile', loc))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(Strings.of('app_title', loc), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            Strings.of('learned_count', loc)
                .replaceFirst('{learned}', state.totalLearned.toString())
                .replaceFirst('{total}', state.totalVerbs.toString()),
          ),
          const SizedBox(height: 24),
          Text(Strings.of('learned_by_level', loc), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in stats.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              trailing: Text(entry.value.toString()),
            ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(Strings.of('dark_theme', loc)),
            value: state.themeMode == ThemeMode.dark ||
                (state.themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark),
            onChanged: (value) {
              state.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(Strings.of('language', loc)),
            subtitle: Text(loc == 'ru' ? Strings.of('russian', loc) : Strings.of('ukrainian', loc)),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ru', label: Text(Strings.of('russian', loc))),
                ButtonSegment(value: 'uk', label: Text(Strings.of('ukrainian', loc))),
              ],
              selected: {loc},
              onSelectionChanged: (value) => state.setLocale(value.first),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.refresh),
            label: Text(Strings.of('reset_progress', loc)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final loc = context.read<AppState>().locale;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of('reset_title', loc)),
        content: Text(Strings.of('reset_text', loc)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.of('cancel', loc)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().resetProgress();
            },
            child: Text(Strings.of('reset', loc)),
          ),
        ],
      ),
    );
  }
}
