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

// Update dialog UI with download progress and auto-show gate widget.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_state.dart';
import '../services/github_update_service.dart';
import '../strings.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.update});

  final UpdateInfo update;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updateService = GithubUpdateService();
  bool _downloading = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppState>().locale;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, size: 28),
          const SizedBox(width: 12),
          Text(Strings.of('update_available', loc)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${Strings.of('new_version', loc)} ${widget.update.version}'),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(_status, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: _downloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Strings.of('later', loc)),
              ),
              FilledButton.icon(
                icon: Icon(widget.update.canAutoUpdate ? Icons.download : Icons.open_in_new),
                label: Text(
                  widget.update.canAutoUpdate
                      ? Strings.of('update_now', loc)
                      : Strings.of('open_releases', loc),
                ),
                onPressed: () {
                  if (widget.update.canAutoUpdate) {
                    _perform(context);
                  } else {
                    _openUrl(context);
                  }
                },
              ),
            ],
    );
  }

  Future<void> _perform(BuildContext context) async {
    final isApk = widget.update.assetName?.endsWith('.apk') == true;

    if (isApk) {
      if (Platform.isAndroid) {
        await _openPlayStore(context);
        return;
      }

      setState(() {
        _downloading = true;
        _status = 'Скачивание...';
      });
      try {
        final filePath = await _updateService.downloadAsset(widget.update);
        if (filePath == null) throw Exception('Download failed');

        setState(() => _status = 'Установка...');
        final installed = await _updateService.installAsset(filePath);

        if (!installed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть файл')),
          );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() {
          _downloading = false;
          _status = '';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    } else {
      await _openUrl(context);
    }
  }

  Future<void> _openPlayStore(BuildContext context) async {
    final uri = Uri.parse('market://details?id=com.dronov.deutsche_verb');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=com.dronov.deutsche_verb'),
        mode: LaunchMode.externalApplication,
      );
    }
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(widget.update.releaseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.pop(context);
  }
}

class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.pendingUpdate != null && !_shown) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => UpdateDialog(update: state.pendingUpdate!),
          );
        }
      });
    }
    return widget.child;
  }
}
