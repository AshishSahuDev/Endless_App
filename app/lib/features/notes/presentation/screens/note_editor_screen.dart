import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/color_picker.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  int _colorIndex = 0;
  bool _isPinned = false;
  Note? _original;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) return;
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNoteById(widget.noteId!);
    if (note == null || !mounted) return;
    _original = note;
    setState(() {
      _titleCtrl.text = note.title;
      _bodyCtrl.text = note.body;
      _colorIndex = note.colorIndex;
      _isPinned = note.isPinned;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();

    try {
      if (_original == null) {
        final note = Note(
          id: 0,
          title: title,
          body: body,
          colorIndex: _colorIndex,
          isPinned: _isPinned,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(notesProvider.notifier).create(note);
      } else {
        final updated = _original!.copyWith(
          title: title,
          body: body,
          colorIndex: _colorIndex,
          isPinned: _isPinned,
          updatedAt: now,
        );
        await ref.read(notesProvider.notifier).save(updated);
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    if (_original == null) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgSecondary,
        title: const Text(kNoteDeleteConfirm, style: TextStyle(color: kTextPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(kCancel, style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(kDelete, style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).delete(_original!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = kNoteColors[_colorIndex % kNoteColors.length];

    return Scaffold(
      backgroundColor: cardBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: kTextPrimary),
          onPressed: _save,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? kAccentPurple : kTextSecondary,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          if (_original != null)
            IconButton(
              icon: Icon(Iconsax.trash, color: Colors.red.shade400),
              onPressed: _delete,
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: kAccentPurple),
              ),
            ),
          const SizedBox(width: kSpaceXS),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingScreen),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: kNoteTitle,
                      hintStyle: TextStyle(color: kTextHint, fontSize: 22, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _bodyCtrl,
                      style: const TextStyle(color: kTextSecondary, fontSize: 15, height: 1.6),
                      decoration: const InputDecoration(
                        hintText: kNoteBody,
                        hintStyle: TextStyle(color: kTextHint, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: kGlassBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kSpaceSM),
            child: NoteColorPicker(
              selectedIndex: _colorIndex,
              onColorSelected: (i) => setState(() => _colorIndex = i),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
