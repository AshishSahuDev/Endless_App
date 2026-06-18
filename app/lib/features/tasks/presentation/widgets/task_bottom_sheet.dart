import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';

class TaskBottomSheet extends ConsumerStatefulWidget {
  final Task? existing;
  const TaskBottomSheet({super.key, this.existing});

  @override
  ConsumerState<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends ConsumerState<TaskBottomSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    if (t != null) {
      _priority = t.priority;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kAccentPurple,
            surface: kBgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    if (widget.existing == null) {
      await ref.read(tasksProvider.notifier).create(Task(
            id: 0,
            title: title,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            createdAt: now,
            updatedAt: now,
          ));
    } else {
      await ref.read(tasksProvider.notifier).save(widget.existing!.copyWith(
            title: title,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            updatedAt: now,
          ));
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
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: kTextHint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: kSpaceMD),
          Text(
            widget.existing == null ? 'New Task' : 'Edit Task',
            style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kSpaceMD),
          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: widget.existing == null,
            style: const TextStyle(color: kTextPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
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
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: kSpaceSM),
          // Note
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: kTextSecondary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: const TextStyle(color: kTextHint, fontSize: 14),
              filled: true,
              fillColor: kBgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMD, vertical: 10),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: kSpaceMD),
          // Priority + Due date row
          Row(
            children: [
              // Priority chips
              Expanded(
                child: Row(
                  children: Priority.values.map((p) {
                    final isSelected = _priority == p;
                    final color = switch (p) {
                      Priority.high => const Color(0xFFEF4444),
                      Priority.medium => kAccentOrange,
                      Priority.low => kAccentGreen,
                    };
                    final label = switch (p) {
                      Priority.high => 'High',
                      Priority.medium => 'Med',
                      Priority.low => 'Low',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: kSpaceXS),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withAlpha(40) : kBgTertiary,
                            borderRadius: BorderRadius.circular(kRadiusRound),
                            border: Border.all(color: isSelected ? color : kGlassBorder),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? color : kTextHint,
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
              // Due date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 6),
                  decoration: BoxDecoration(
                    color: _dueDate != null ? kAccentBlue.withAlpha(30) : kBgTertiary,
                    borderRadius: BorderRadius.circular(kRadiusRound),
                    border: Border.all(color: _dueDate != null ? kAccentBlue : kGlassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.calendar_1, size: 14,
                          color: _dueDate != null ? kAccentBlue : kTextHint),
                      const SizedBox(width: 4),
                      Text(
                        _dueDate != null
                            ? DateFormat('d MMM').format(_dueDate!)
                            : 'Due date',
                        style: TextStyle(
                          color: _dueDate != null ? kAccentBlue : kTextHint,
                          fontSize: 12,
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close, size: 12, color: kTextHint),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpaceMD),
          // Save button
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
                widget.existing == null ? 'Add Task' : 'Save Changes',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
