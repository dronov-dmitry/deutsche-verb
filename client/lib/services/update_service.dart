import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String currentVersion = '1.0.0';
  static const _apiUrl =
      'https://api.github.com/repos/dronov-dmitry/deutsche-verb/releases/latest';
  static const _releasesUrl =
      'https://github.com/dronov-dmitry/deutsche-verb/releases';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _client
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (version.isEmpty || !_isNewer(version)) return null;

      final assets = data['assets'] as List<dynamic>? ?? [];
      String? downloadUrl;
      String? assetName;

      final key = _platformAssetKey();
      if (key != null) {
        for (final a in assets) {
          final name = a['name'] as String? ?? '';
          if (name.contains(key)) {
            downloadUrl = a['browser_download_url'] as String?;
            assetName = name;
            break;
          }
        }
      }

      return UpdateInfo(
        version: version,
        tagName: tagName,
        downloadUrl: downloadUrl,
        assetName: assetName,
        releaseUrl: '$_releasesUrl/tag/$tagName',
      );
    } catch (_) {
      return null;
    }
  }

  static String? _platformAssetKey() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android.apk';
    if (Platform.isIOS) return 'ios-unsigned.zip';
    if (Platform.isWindows) return 'windows-x64.zip';
    if (Platform.isLinux) return 'linux-x64.tar.gz';
    if (Platform.isMacOS) return 'macos.zip';
    return null;
  }

  bool _isNewer(String version) {
    final current = _parse(UpdateService.currentVersion);
    final remote = _parse(version);
    if (current == null || remote == null) return false;
    for (int i = 0; i < 3; i++) {
      if (remote[i] > current[i]) return true;
      if (remote[i] < current[i]) return false;
    }
    return false;
  }

  List<int>? _parse(String v) {
    final parts = v.split('.');
    if (parts.length != 3) return null;
    return [for (final p in parts) int.tryParse(p) ?? 0];
  }
}

class UpdateInfo {
  UpdateInfo({
    required this.version,
    required this.tagName,
    required this.downloadUrl,
    required this.assetName,
    required this.releaseUrl,
  });

  final String version;
  final String tagName;
  final String? downloadUrl;
  final String? assetName;
  final String releaseUrl;

  bool get canAutoUpdate => downloadUrl != null;
}
