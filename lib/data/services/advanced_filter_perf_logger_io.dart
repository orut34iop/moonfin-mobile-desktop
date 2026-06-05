import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AdvancedFilterPerfLogger {
  static Future<void>? _initFuture;
  static Future<void> _writeChain = Future<void>.value();
  static File? _file;

  static void write(String message) {
    final line = _line(message);
    developer.log(line, name: 'AdvancedFilterPerf');
    _writeChain = _writeChain
        .catchError((_) {})
        .then((_) => _append(line))
        .catchError((error, stackTrace) {
          developer.log(
            'Failed to write advanced filter perf log',
            name: 'AdvancedFilterPerf',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  static Future<String> getLogPath() async {
    final file = await _ensureFile();
    return file.path;
  }

  static String _line(String message) {
    return '${DateTime.now().toIso8601String()} $message';
  }

  static Future<void> _append(String line) async {
    final file = await _ensureFile();
    await file.writeAsString('$line\n', mode: FileMode.append);
  }

  static Future<File> _ensureFile() async {
    final existing = _file;
    if (existing != null) return existing;

    await (_initFuture ??= _init());
    return _file!;
  }

  static Future<void> _init() async {
    Directory docs;
    try {
      docs = await getApplicationDocumentsDirectory();
    } catch (_) {
      docs = Directory.systemTemp;
    }
    final dir = Directory('${docs.path}/Moonfin/logs');
    await dir.create(recursive: true);
    final file = File('${dir.path}/advanced_filter_perf.log');
    _file = file;
    await file.writeAsString(
      '\n--- AdvancedFilterPerf session ${DateTime.now().toIso8601String()} ---\n',
      mode: FileMode.append,
    );
  }
}
