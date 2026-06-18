import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? kSpaceXS : kSpaceSM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(kRadiusRound),
        border: Border.all(color: _color.withAlpha(80), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(_label, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Color get _color => switch (priority) {
        Priority.high => const Color(0xFFEF4444),
        Priority.medium => kAccentOrange,
        Priority.low => kAccentGreen,
      };

  String get _label => switch (priority) {
        Priority.high => 'High',
        Priority.medium => 'Medium',
        Priority.low => 'Low',
      };
}
