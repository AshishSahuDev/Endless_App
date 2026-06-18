import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';
import 'priority_badge.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref.read(tasksProvider.notifier).delete(task.id),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: Iconsax.trash,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(kRadiusMD),
              bottomRight: Radius.circular(kRadiusMD),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: kSpaceSM),
          padding: const EdgeInsets.symmetric(horizontal: kPaddingCard, vertical: 12),
          decoration: BoxDecoration(
            color: kBgSecondary,
            borderRadius: BorderRadius.circular(kRadiusMD),
            border: Border.all(
              color: task.isOverdue ? const Color(0x33EF4444) : kGlassBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => ref.read(tasksProvider.notifier).toggleComplete(task.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? kAccentPurple : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? kAccentPurple : kTextHint,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: kSpaceMD),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isCompleted ? kTextHint : kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: kTextHint,
                      ),
                    ),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.note!,
                        style: const TextStyle(color: kTextHint, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PriorityBadge(priority: task.priority),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: kSpaceSM),
                          Icon(
                            Iconsax.calendar_1,
                            size: 11,
                            color: task.isOverdue ? const Color(0xFFEF4444) : kTextHint,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            du.formatDate(task.dueDate!),
                            style: TextStyle(
                              color: task.isOverdue ? const Color(0xFFEF4444) : kTextHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Drag handle (only for active tasks)
              if (!task.isCompleted)
                const Icon(Icons.drag_handle, color: kTextHint, size: kIconMD),
            ],
          ),
        ),
      ),
    );
  }
}
