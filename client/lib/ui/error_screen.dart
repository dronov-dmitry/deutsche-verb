// Startup error screen with crash report and Telegram sharing.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update.dart';
import 'update_dialog.dart';

/// Shown instead of a black screen when startup throws.
/// Displays the full error + stack trace so it can be read directly on device.
class ErrorApp extends StatefulWidget {
  const ErrorApp({
    super.key,
    required this.error,
    required this.stack,
    this.preFetchedUpdate,
  });

  final Object error;
  final StackTrace stack;
  final UpdateInfo? preFetchedUpdate;

  @override
  State<ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<ErrorApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static const _telegramUsername = 'DmitryDronov';

  @override
  void initState() {
    super.initState();
    if (widget.preFetchedUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final ctx = _navigatorKey.currentContext;
          if (ctx != null) {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => UpdateDialog(update: widget.preFetchedUpdate!),
            );
          }
        }
      });
    }
  }

  static const _maxReportLength = 3000;

  bool _copied = false;

  String _sysInfo() {
    try {
      return 'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
          'Dart: ${Platform.version}';
    } catch (_) {
      return 'OS: unknown';
    }
  }

  String _buildReport() {
    final sys = _sysInfo();

    var err = widget.error.toString();
    final previewIdx = err.indexOf('Statement preview:');
    if (previewIdx > 0) {
      err = '${err.substring(0, previewIdx).trimRight()}\n[SQL preview omitted]';
    }
    if (err.length > 800) {
      err = '${err.substring(0, 800)}\n…[truncated]';
    }

    final stackLines = widget.stack.toString().split('\n');
    final stackShort = stackLines.take(15).join('\n');
    final stackSuffix =
        stackLines.length > 15 ? '\n…[+${stackLines.length - 15} frames]' : '';

    final report =
        '🐛 DeutscheVerb crash\n\n'
        '📱 $sys\n\n'
        '❌ Error\n$err\n\n'
        '📋 Stack\n$stackShort$stackSuffix';

    if (report.length > _maxReportLength) {
      return '${report.substring(0, _maxReportLength)}\n…[truncated]';
    }
    return report;
  }

  Future<void> _sendToTelegram() async {
    final report = _buildReport();

    bool copied = false;
    try {
      await Clipboard.setData(ClipboardData(text: report));
      copied = true;
    } catch (_) {}

    if (!copied) {
      try {
        const ch = MethodChannel('flutter/platform');
        await ch.invokeMethod<void>('Clipboard.setData', {'text': report});
        copied = true;
      } catch (_) {}
    }

    if (mounted) setState(() => _copied = copied);

    for (final uri in [
      Uri.parse('tg://resolve?domain=$_telegramUsername'),
      Uri.parse('https://t.me/$_telegramUsername'),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Startup Error',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _copied ? Colors.green.shade700 : const Color(0xFF0088CC),
                    ),
                    icon: Icon(_copied ? Icons.check : Icons.telegram),
                    label: Text(
                      _copied
                          ? 'Скопировано — вставь в чат'
                          : 'Скопировать ошибку и открыть Telegram',
                    ),
                    onPressed: _sendToTelegram,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Нажми кнопку — текст ошибки скопируется в буфер, '
                  'затем вставь его в чат @$_telegramUsername',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _card(
                  label: 'System',
                  content: _sysInfo(),
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _card(
                        label: 'Error',
                        content: widget.error.toString(),
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      _card(
                        label: 'Stack trace',
                        content: widget.stack.toString(),
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String label,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 6),
          SelectableText(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
