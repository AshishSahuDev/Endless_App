import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/alarm_entity.dart';
import '../providers/alarms_provider.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        title: const Text(
          kNavAlarms,
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
        error: (_, __) => const Center(child: Text(kError, style: TextStyle(color: kTextSecondary))),
        data: (alarms) {
          if (alarms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.clock, size: 64, color: kTextHint),
                  SizedBox(height: kSpaceMD),
                  Text(
                    'No alarms set.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextHint, fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                kPaddingScreen, kSpaceSM, kPaddingScreen, kSpaceXXL + kFabSize),
            itemCount: alarms.length,
            itemBuilder: (_, i) => _AlarmCard(alarm: alarms[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAlarmSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  final AlarmEntity alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpaceSM),
      padding: const EdgeInsets.symmetric(horizontal: kPaddingCard, vertical: 14),
      decoration: BoxDecoration(
        color: alarm.isEnabled ? kBgSecondary : kBgTertiary,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(color: kGlassBorder, width: 0.8),
      ),
      child: Row(
        children: [
          // Time display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.timeString,
                  style: TextStyle(
                    color: alarm.isEnabled ? kTextPrimary : kTextHint,
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                Row(
                  children: [
                    if (alarm.label.isNotEmpty) ...[
                      Text(alarm.label,
                          style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                      const Text(' · ',
                          style: TextStyle(color: kTextHint, fontSize: 13)),
                    ],
                    Text(
                      alarm.repeatLabel,
                      style: const TextStyle(color: kTextHint, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Toggle + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: alarm.isEnabled,
                onChanged: (_) => ref.read(alarmsProvider.notifier).toggle(alarm.id),
                activeThumbColor: kAccentPurple,
                inactiveThumbColor: kTextHint,
                inactiveTrackColor: kBgTertiary,
              ),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Iconsax.trash, size: kIconSM, color: kTextHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: const Text('Delete alarm?', style: TextStyle(color: kTextPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(alarmsProvider.notifier).delete(alarm.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Alarm Bottom Sheet
// ─────────────────────────────────────────────

void _showAlarmSheet(BuildContext context, {AlarmEntity? existing}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AlarmSheet(existing: existing),
  );
}

class _AlarmSheet extends ConsumerStatefulWidget {
  final AlarmEntity? existing;
  const _AlarmSheet({this.existing});

  @override
  ConsumerState<_AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends ConsumerState<_AlarmSheet> {
  late TextEditingController _labelCtrl;
  late TimeOfDay _time;
  late int _repeatDays;
  late String _sound;

  static const _sounds = [
    ('Default', 'assets/sounds/alarm_default.mp3'),
    ('Gentle', 'assets/sounds/alarm_gentle.mp3'),
    ('Digital', 'assets/sounds/alarm_digital.mp3'),
    ('Birds', 'assets/sounds/alarm_birds.mp3'),
    ('Classic', 'assets/sounds/alarm_classic.mp3'),
  ];

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _time = a != null
        ? TimeOfDay(hour: a.hour, minute: a.minute)
        : TimeOfDay.now();
    _repeatDays = a?.repeatDays ?? 0;
    _sound = a?.soundAsset ?? _sounds[0].$2;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kAccentPurple, surface: kBgSecondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final alarm = AlarmEntity(
      id: widget.existing?.id ?? 0,
      label: _labelCtrl.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _repeatDays,
      soundAsset: _sound,
      createdAt: widget.existing?.createdAt ?? now,
    );

    if (widget.existing == null) {
      await ref.read(alarmsProvider.notifier).create(alarm);
    } else {
      await ref.read(alarmsProvider.notifier).save(alarm);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(kPaddingScreen, kSpaceMD, kPaddingScreen, kSpaceMD + bottomInset),
      decoration: const BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: kTextHint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: kSpaceMD),
          Text(
            widget.existing == null ? 'New Alarm' : 'Edit Alarm',
            style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kSpaceLG),
          // Large time display — tap to change
          Center(
            child: GestureDetector(
              onTap: _pickTime,
              child: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Tap to change time',
              style: TextStyle(color: kTextHint, fontSize: 12),
            ),
          ),
          const SizedBox(height: kSpaceLG),
          // Label
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Label (e.g. Wake up, Gym)',
              hintStyle: const TextStyle(color: kTextHint),
              filled: true,
              fillColor: kBgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMD, vertical: 12),
            ),
          ),
          const SizedBox(height: kSpaceMD),
          // Repeat days
          const Text('Repeat', style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: kSpaceXS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isOn = _repeatDays & (1 << i) != 0;
              return GestureDetector(
                onTap: () => setState(() => _repeatDays ^= (1 << i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isOn ? kAccentPurple : kBgTertiary,
                    shape: BoxShape.circle,
                    border: Border.all(color: isOn ? kAccentPurple : kGlassBorder),
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        color: isOn ? Colors.white : kTextHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: kSpaceMD),
          // Sound selector
          const Text('Sound', style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: kSpaceXS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sounds.map((s) {
                final isSelected = _sound == s.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: kSpaceXS),
                  child: GestureDetector(
                    onTap: () => setState(() => _sound = s.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? kAccentPurple.withAlpha(40) : kBgTertiary,
                        borderRadius: BorderRadius.circular(kRadiusRound),
                        border: Border.all(color: isSelected ? kAccentPurple : kGlassBorder),
                      ),
                      child: Text(
                        s.$1,
                        style: TextStyle(
                          color: isSelected ? kAccentPurple : kTextHint,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: kSpaceMD),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: kAccentPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMD)),
              ),
              child: Text(
                widget.existing == null ? 'Set Alarm' : 'Save Alarm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
