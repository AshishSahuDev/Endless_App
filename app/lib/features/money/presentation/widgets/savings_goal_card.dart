import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/savings_goal.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onAddFunds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    final completed = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? kAccentGreen.withAlpha(80) : kGlassBorder,
          width: completed ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle_rounded,
                    color: kAccentGreen, size: 18),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: kTextHint, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_fmt(goal.savedAmount)}',
                style: const TextStyle(
                    color: kAccentPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'of ₹${_fmt(goal.targetAmount)}',
                style: const TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: kBgTertiary,
              valueColor: AlwaysStoppedAnimation(
                  completed ? kAccentGreen : kAccentPurple),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% saved',
                style: const TextStyle(color: kTextHint, fontSize: 12),
              ),
              if (goal.deadline != null)
                Text(
                  _deadlineLabel(goal.deadline!),
                  style: TextStyle(
                    color: _isOverdue(goal.deadline!)
                        ? Colors.redAccent
                        : kTextHint,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (!completed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAddFunds,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kAccentPurple),
                  foregroundColor: kAccentPurple,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add Funds', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static String _deadlineLabel(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  static bool _isOverdue(DateTime d) => d.isBefore(DateTime.now());
}
