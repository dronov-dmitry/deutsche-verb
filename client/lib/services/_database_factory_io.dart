import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDatabaseFactory() {
  // macOS uses sqflite_darwin natively; Android/iOS use native sqflite.
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
