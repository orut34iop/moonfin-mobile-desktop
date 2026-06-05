import 'dart:developer' as developer;

class AdvancedFilterPerfLogger {
  static void write(String message) {
    developer.log(_line(message), name: 'AdvancedFilterPerf');
  }

  static Future<String> getLogPath() async => 'debug console';

  static String _line(String message) {
    return '${DateTime.now().toIso8601String()} $message';
  }
}
