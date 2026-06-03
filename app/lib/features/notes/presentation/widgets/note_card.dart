import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../domain/entities/note.dart';
import '../providers/notes_provider.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardColor = kNoteColors[note.colorIndex % kNoteColors.length];

    return Slidable(
      key: ValueKey(note.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref.read(notesProvider.notifier).togglePin(note.id),
            backgroundColor: kAccentPurple,
            foregroundColor: Colors.white,
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.isPinned ? 'Unpin' : 'Pin',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kRadiusMD),
              bottomLeft: Radius.circular(kRadiusMD),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref.read(notesProvider.notifier).toggleArchive(note.id),
            backgroundColor: kAccentBlue,
            foregroundColor: Colors.white,
            icon: Iconsax.archive_add,
            label: 'Archive',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: Iconsax.trash,
            label: kDelete,
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
          padding: const EdgeInsets.all(kPaddingCard),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(kRadiusMD),
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          constraints: const BoxConstraints(minHeight: kNoteCardMinHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    const Icon(Icons.push_pin, size: kIconSM, color: kAccentPurple),
                    const SizedBox(width: kSpaceXS),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? kNoteBody : note.title,
                      style: TextStyle(
                        color: note.title.isEmpty ? kTextHint : kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: kSpaceXS),
                Text(
                  note.body,
                  style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: kSpaceSM),
              Text(
                du.formatDate(note.updatedAt),
                style: const TextStyle(color: kTextHint, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: const Text(kNoteDeleteConfirm, style: TextStyle(color: kTextPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(kCancel, style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notesProvider.notifier).delete(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(kNoteDeletedMsg)),
              );
            },
            child: Text(kDelete, style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
