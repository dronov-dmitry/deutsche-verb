import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/local/local_cache.dart';
import 'providers/app_state.dart';
import 'repositories/verb_repository.dart';
import 'services/database_service.dart';
import 'ui/home_shell.dart';
import 'ui/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UpdateInfo? preFetchedUpdate;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final service = UpdateService(currentVersion: packageInfo.version);
    preFetchedUpdate = await service.checkForUpdate();
  } catch (_) {}

  try {
    final databaseService = DatabaseService();
    final localCache = LocalCache(databaseService);
    await localCache.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(
              verbRepository: VerbRepository(localCache),
              localCache: localCache,
              preFetchedUpdate: preFetchedUpdate,
            )..bootstrap(),
          ),
        ],
        child: const DeutscheVerbApp(),
      ),
    );
  } catch (e, stack) {
    runApp(_ErrorApp(
      error: e,
      stack: stack,
      preFetchedUpdate: preFetchedUpdate,
    ));
  }
}

class DeutscheVerbApp extends StatelessWidget {
  const DeutscheVerbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Deutsche Verb',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D)),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8B8D), brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: state.themeMode,
          home: state.isBootstrapping
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : const UpdateGate(child: HomeShell()),
        );
      },
    );
  }
}

/// Shown instead of a black screen when [main] throws during startup.
/// Displays the full error + stack trace so it can be read directly on device.
class _ErrorApp extends StatefulWidget {
  const _ErrorApp({
    required this.error,
    required this.stack,
    this.preFetchedUpdate,
  });

  final Object error;
  final StackTrace stack;
  final UpdateInfo? preFetchedUpdate;

  @override
  State<_ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<_ErrorApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static const _telegramUsername = 'DmitryDronov';
  // Android IPC limit is ~1MB. Keep well under it.
  static const _maxClipboardBytes = 800000; // 800 KB

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

  /// Builds a compact report that fits in Android clipboard (< 1 MB IPC limit).
  ///
  /// Strategy:
  ///  1. Always include: header + system info
  ///  2. Error text — truncated to 800 chars (SQL dumps can be huge)
  ///  3. Stack trace — first 15 frames only
  String _buildReport() {
    final sys = _sysInfo();

    // Truncate error: strip everything after "Statement preview:" if present
    var err = widget.error.toString();
    final previewIdx = err.indexOf('Statement preview:');
    if (previewIdx > 0) {
      err = '${err.substring(0, previewIdx).trimRight()}\n[SQL preview omitted]';
    }
    if (err.length > 800) {
      err = '${err.substring(0, 800)}\n…[truncated]';
    }

    // Stack trace: keep first 15 lines
    final stackLines = widget.stack.toString().split('\n');
    final stackShort = stackLines.take(15).join('\n');
    final stackSuffix =
        stackLines.length > 15 ? '\n…[+${stackLines.length - 15} frames]' : '';

    final report =
        '🐛 DeutscheVerb crash\n\n'
        '📱 $sys\n\n'
        '❌ Error\n$err\n\n'
        '📋 Stack\n$stackShort$stackSuffix';

    // Final safety clamp — should never be needed after above truncation
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

    // Open Telegram — native deep-link first, browser fallback
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
              // ── Send button ──────────────────────────────────────────────
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
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // ── System info ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _card(
                  label: 'System',
                  content: _sysInfo(),
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              // ── Scrollable error text ────────────────────────────────────
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

  Widget _card(
      {required String label,
      required String content,
      required Color color}) {
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
