import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warn, error, action }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Map<String, Object?>? data;
  final String? error;
  final String? stack;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.data,
    this.error,
    this.stack,
  });

  String get levelName => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
        LogLevel.action => 'ACTION',
      };

  Map<String, Object?> toJson() => {
        'ts': timestamp.toIso8601String(),
        'lvl': levelName,
        'tag': tag,
        'msg': message,
        if (data != null) 'data': data,
        if (error != null) 'err': error,
        if (stack != null) 'stack': stack,
      };

  String toLine() {
    final buf = StringBuffer()
      ..write(timestamp.toIso8601String())
      ..write(' [')
      ..write(levelName.padRight(6))
      ..write('] ')
      ..write(tag)
      ..write(': ')
      ..write(message);
    if (data != null && data!.isNotEmpty) {
      buf.write(' ');
      buf.write(jsonEncode(data));
    }
    if (error != null) buf..write(' | err=')..write(error);
    if (stack != null) buf..write('\n')..write(stack);
    return buf.toString();
  }
}

/// File-backed usage logger. Singleton.
///
/// Captures user actions, lifecycle events, and errors. Maintains a 500-entry
/// in-memory ring buffer for the in-app viewer, and appends every entry to
/// `<app_documents>/logs/app.log` (rotates at ~1 MB into `app.log.1`).
class AppLogger {
  AppLogger._();
  static final AppLogger I = AppLogger._();

  static const int _bufferLimit = 500;
  static const int _rotateBytes = 1024 * 1024; // 1 MB

  final Queue<LogEntry> _buffer = Queue();
  final StreamController<LogEntry> _controller = StreamController.broadcast();

  File? _file;
  bool _initialized = false;

  Stream<LogEntry> get stream => _controller.stream;
  List<LogEntry> get buffer => List.unmodifiable(_buffer);
  File? get currentFile => _file;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/logs');
      if (!await dir.exists()) await dir.create(recursive: true);
      _file = File('${dir.path}/app.log');
      if (!await _file!.exists()) await _file!.create();
      _initialized = true;
      info('logger', 'logger ready', data: {'path': _file!.path});
    } catch (e, s) {
      // Logging must never crash the app — fall back to in-memory only.
      dev.log('AppLogger init failed: $e', stackTrace: s, name: 'logger');
    }
  }

  void debug(String tag, String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.debug, tag, message, data: data);

  void info(String tag, String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.info, tag, message, data: data);

  void warn(String tag, String message, {Map<String, Object?>? data}) =>
      _log(LogLevel.warn, tag, message, data: data);

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?>? data,
  }) =>
      _log(LogLevel.error, tag, message,
          data: data, error: error?.toString(), stack: stack?.toString());

  /// User-initiated action — primary tool for usage analytics.
  void action(String tag, String name, {Map<String, Object?>? data}) =>
      _log(LogLevel.action, tag, name, data: data);

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Map<String, Object?>? data,
    String? error,
    String? stack,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      data: data,
      error: error,
      stack: stack,
    );

    _buffer.addLast(entry);
    while (_buffer.length > _bufferLimit) {
      _buffer.removeFirst();
    }
    if (!_controller.isClosed) _controller.add(entry);

    if (kDebugMode) {
      dev.log(entry.toLine(), name: tag, level: _devLevel(level));
    }

    // Fire-and-forget file write — never await in callers.
    unawaited(_appendToFile(entry));
  }

  int _devLevel(LogLevel l) => switch (l) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.action => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      };

  Future<void> _appendToFile(LogEntry entry) async {
    final f = _file;
    if (f == null) return;
    try {
      await f.writeAsString('${entry.toLine()}\n',
          mode: FileMode.append, flush: false);
      // Rotate if file grew past the limit.
      final len = await f.length();
      if (len > _rotateBytes) await _rotate();
    } catch (_) {
      // Swallow — logger failures must never break the app.
    }
  }

  Future<void> _rotate() async {
    final f = _file;
    if (f == null) return;
    try {
      final rotated = File('${f.path}.1');
      if (await rotated.exists()) await rotated.delete();
      await f.rename(rotated.path);
      _file = File(f.path);
      await _file!.create();
    } catch (_) {/* ignore */}
  }

  Future<String> exportAsText() async {
    final f = _file;
    if (f == null || !await f.exists()) {
      return _buffer.map((e) => e.toLine()).join('\n');
    }
    return f.readAsString();
  }

  Future<void> clear() async {
    _buffer.clear();
    final f = _file;
    if (f != null && await f.exists()) {
      await f.writeAsString('');
    }
    final rotated = File('${f?.path}.1');
    if (await rotated.exists()) await rotated.delete();
    info('logger', 'logs cleared');
  }
}

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.I);
