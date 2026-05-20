import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_state.dart';
import '../strings.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppState>().locale;

    return Scaffold(
      appBar: AppBar(title: Text(Strings.of('info_title', locale))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.info_outline, size: 64),
          const SizedBox(height: 16),
          Text(
            Strings.of('app_title', locale),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Strings.of('info_desc', locale),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            Strings.of('author', locale),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(Strings.of('author_name', locale)),
          const SizedBox(height: 16),
          Text(Strings.of('author_desc', locale)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openUrl(context, 'https://dronov-dmitry.github.io/'),
            icon: const Icon(Icons.open_in_new),
            label: Text(Strings.of('website', locale)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(context, 'https://github.com/dronov-dmitry/'),
            icon: const Icon(Icons.code),
            label: Text(Strings.of('github_profile', locale)),
          ),
        ],
      ),
    );
  }

  void _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$url')),
        );
      }
    }
  }
}
