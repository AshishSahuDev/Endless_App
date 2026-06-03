import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class NoteColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kPaddingScreen),
        itemCount: kNoteColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: kSpaceSM),
        itemBuilder: (_, i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onColorSelected(i),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kNoteColors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kAccentPurple : kGlassBorder,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: kAccentPurple, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
