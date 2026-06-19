import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_logger.dart';

final _filterProvider = StateProvider<LogLevel?>((_) => null);

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  late final StreamSubscription<LogEntry> _sub;

  @override
  void initState() {
    super.initState();
    _sub = AppLogger.I.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _copyAll() async {
    final text = await AppLogger.I.exportAsText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  Future<void> _clear() async {
    await AppLogger.I.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final entries = AppLogger.I.buffer.reversed
        .where((e) => filter == null || e.level == filter)
        .toList();

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        title: const Text('Diagnostic Logs',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        iconTheme: const IconThemeData(color: kTextSecondary),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Iconsax.copy, color: kTextSecondary),
            onPressed: _copyAll,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Iconsax.trash, color: kTextSecondary),
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(active: filter),
          if (entries.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No log entries',
                    style: TextStyle(color: kTextHint)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _LogTile(entry: entries[i]),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kBgSecondary,
            child: Row(
              children: [
                Text('${entries.length} entries (buffer: ${AppLogger.I.buffer.length}/500)',
                    style: const TextStyle(color: kTextHint, fontSize: 11)),
                const Spacer(),
                if (AppLogger.I.currentFile != null)
                  Text(
                    'file: ${AppLogger.I.currentFile!.path.split('/').last}',
                    style: const TextStyle(color: kTextHint, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final LogLevel? active;
  const _FilterBar({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = <(String, LogLevel?)>[
      ('All', null),
      ('Action', LogLevel.action),
      ('Info', LogLevel.info),
      ('Warn', LogLevel.warn),
      ('Error', LogLevel.error),
      ('Debug', LogLevel.debug),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: levels.map((l) {
          final selected = l.$2 == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(_filterProvider.notifier).state = l.$2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? kAccentPurple.withAlpha(60) : kBgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? kAccentPurple : kGlassBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  l.$1,
                  style: TextStyle(
                    color: selected ? kAccentPurple : kTextSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  const _LogTile({required this.entry});

  Color get _levelColor => switch (entry.level) {
        LogLevel.debug => kTextHint,
        LogLevel.info => kAccentBlue,
        LogLevel.action => kAccentGreen,
        LogLevel.warn => kAccentOrange,
        LogLevel.error => kAccentPink,
      };

  String _hhmmss(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _levelColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(entry.levelName,
                  style: TextStyle(
                      color: _levelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(entry.tag,
                  style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_hhmmss(entry.timestamp),
                  style: const TextStyle(color: kTextHint, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(entry.message,
              style: const TextStyle(color: kTextPrimary, fontSize: 12)),
          if (entry.data != null && entry.data!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(entry.data.toString(),
                style: const TextStyle(
                    color: kTextHint, fontSize: 10, fontFamily: 'monospace')),
          ],
          if (entry.error != null) ...[
            const SizedBox(height: 2),
            Text(entry.error!,
                style: const TextStyle(
                    color: kAccentPink, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
