import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        title: const Text(
          kNavReminders,
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
        error: (_, __) => const Center(child: Text(kError, style: TextStyle(color: kTextSecondary))),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.notification, size: 64, color: kTextHint),
                  SizedBox(height: kSpaceMD),
                  Text(
                    'No reminders yet.\nTap + to add one.',
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
            itemCount: reminders.length,
            itemBuilder: (_, i) => _ReminderCard(reminder: reminders[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = reminder.isPast;
    final isTriggered = reminder.isTriggered;

    return Container(
      margin: const EdgeInsets.only(bottom: kSpaceSM),
      padding: const EdgeInsets.all(kPaddingCard),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(
          color: isPast && !isTriggered
              ? const Color(0x33EF4444)
              : isTriggered
                  ? kGlassBorder.withAlpha(40)
                  : kGlassBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTriggered
                  ? kBgTertiary
                  : isPast
                      ? const Color(0x22EF4444)
                      : kAccentPurple.withAlpha(30),
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
            child: Icon(
              isTriggered
                  ? Icons.check_circle_outline
                  : isPast
                      ? Iconsax.notification_status
                      : Iconsax.notification,
              size: kIconMD,
              color: isTriggered
                  ? kTextHint
                  : isPast
                      ? const Color(0xFFEF4444)
                      : kAccentPurple,
            ),
          ),
          const SizedBox(width: kSpaceMD),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    color: isTriggered ? kTextHint : kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: isTriggered ? TextDecoration.lineThrough : null,
                    decorationColor: kTextHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy, h:mm a').format(reminder.reminderAt),
                  style: TextStyle(
                    color: isPast && !isTriggered
                        ? const Color(0xFFEF4444)
                        : kTextHint,
                    fontSize: 12,
                  ),
                ),
                if (reminder.recurring != RecurringInterval.none) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.repeat, size: 11, color: kAccentBlue),
                      const SizedBox(width: 3),
                      Text(
                        _recurringLabel(reminder.recurring),
                        style: const TextStyle(color: kAccentBlue, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTriggered)
                GestureDetector(
                  onTap: () => ref.read(remindersProvider.notifier).snooze(reminder.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentBlue.withAlpha(30),
                      borderRadius: BorderRadius.circular(kRadiusRound),
                      border: Border.all(color: kAccentBlue.withAlpha(80)),
                    ),
                    child: const Text(
                      '+10m',
                      style: TextStyle(color: kAccentBlue, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(height: kSpaceXS),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: const Icon(Iconsax.trash, size: kIconSM, color: kTextHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _recurringLabel(RecurringInterval r) => switch (r) {
        RecurringInterval.none => '',
        RecurringInterval.daily => 'Daily',
        RecurringInterval.weekly => 'Weekly',
        RecurringInterval.monthly => 'Monthly',
      };

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: const Text('Delete reminder?', style: TextStyle(color: kTextPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(remindersProvider.notifier).delete(reminder.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Reminder Bottom Sheet
// ─────────────────────────────────────────────

void _showReminderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddReminderSheet(),
  );
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  RecurringInterval _recurring = RecurringInterval.none;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kAccentPurple, surface: kBgSecondary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kAccentPurple, surface: kBgSecondary),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time')),
      );
      return;
    }

    final at = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (at.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a future time')),
      );
      return;
    }

    try {
      await ref.read(remindersProvider.notifier).create(Reminder(
            id: 0,
            title: _titleCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            reminderAt: at,
            recurring: _recurring,
            createdAt: DateTime.now(),
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
          const Text('New Reminder',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: kSpaceMD),
          _inputField(_titleCtrl, 'Reminder title', autofocus: true),
          const SizedBox(height: kSpaceSM),
          _inputField(_noteCtrl, 'Note (optional)'),
          const SizedBox(height: kSpaceMD),
          // Date + Time row
          Row(
            children: [
              Expanded(
                child: _PickerChip(
                  icon: Iconsax.calendar_1,
                  label: _selectedDate != null
                      ? DateFormat('d MMM yyyy').format(_selectedDate!)
                      : 'Pick date',
                  onTap: _pickDate,
                  isSet: _selectedDate != null,
                ),
              ),
              const SizedBox(width: kSpaceSM),
              Expanded(
                child: _PickerChip(
                  icon: Iconsax.clock,
                  label: _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Pick time',
                  onTap: _pickTime,
                  isSet: _selectedTime != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceSM),
          // Recurring
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RecurringInterval.values.map((r) {
                final isSelected = _recurring == r;
                final label = switch (r) {
                  RecurringInterval.none => 'Once',
                  RecurringInterval.daily => 'Daily',
                  RecurringInterval.weekly => 'Weekly',
                  RecurringInterval.monthly => 'Monthly',
                };
                return Padding(
                  padding: const EdgeInsets.only(right: kSpaceXS),
                  child: GestureDetector(
                    onTap: () => setState(() => _recurring = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? kAccentPurple.withAlpha(40) : kBgTertiary,
                        borderRadius: BorderRadius.circular(kRadiusRound),
                        border: Border.all(color: isSelected ? kAccentPurple : kGlassBorder),
                      ),
                      child: Text(
                        label,
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
              child: const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, {bool autofocus = false}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      style: const TextStyle(color: kTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextHint),
        filled: true,
        fillColor: kBgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMD, vertical: 12),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

class _PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSet;
  const _PickerChip({required this.icon, required this.label, required this.onTap, required this.isSet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 10),
        decoration: BoxDecoration(
          color: isSet ? kAccentPurple.withAlpha(20) : kBgTertiary,
          borderRadius: BorderRadius.circular(kRadiusMD),
          border: Border.all(color: isSet ? kAccentPurple.withAlpha(100) : kGlassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSet ? kAccentPurple : kTextHint),
            const SizedBox(width: kSpaceXS),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: isSet ? kAccentPurple : kTextHint, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
