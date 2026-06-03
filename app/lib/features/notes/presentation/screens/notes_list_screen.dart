import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNote({int? noteId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: noteId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = _isSearching
        ? ref.watch(noteSearchResultsProvider)
        : ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: _buildAppBar(),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
        error: (e, _) => const Center(
          child: Text(kError, style: TextStyle(color: kTextSecondary)),
        ),
        data: (notes) {
          if (notes.isEmpty) return _buildEmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              kPaddingScreen,
              kSpaceMD,
              kPaddingScreen,
              kSpaceXXL + kFabSize,
            ),
            itemCount: notes.length,
            itemBuilder: (_, i) => NoteCard(
              note: notes[i],
              onTap: () => _openNote(noteId: notes[i].id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNote(),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kBgPrimary,
      elevation: 0,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                hintText: kSearch,
                hintStyle: TextStyle(color: kTextHint),
                border: InputBorder.none,
              ),
              onChanged: (q) => ref.read(noteSearchQueryProvider.notifier).state = q,
            )
          : const Text(
              kNavNotes,
              style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Iconsax.close_circle : Iconsax.search_normal,
            color: kTextSecondary,
          ),
          onPressed: () {
            setState(() => _isSearching = !_isSearching);
            if (!_isSearching) {
              _searchController.clear();
              ref.read(noteSearchQueryProvider.notifier).state = '';
            }
          },
        ),
        const SizedBox(width: kSpaceXS),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.note_text, size: 64, color: kTextHint),
          SizedBox(height: kSpaceMD),
          Text(
            kNoteEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextHint, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
