// App info screen: version, author links, video guide.

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
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_state.dart';
import '../strings.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locale = state.locale;

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
          const SizedBox(height: 4),
          if (state.appVersion.isNotEmpty)
            Text(
              'v${state.appVersion}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(context, 'https://youtu.be/MbzCh3P16tI'),
            icon: const Icon(Icons.video_library),
            label: Text(Strings.of('video_guide', locale)),
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
          SnackBar(content: Text(url)),
        );
      }
    }
  }
}
