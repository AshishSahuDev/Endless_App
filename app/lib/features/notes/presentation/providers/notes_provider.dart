import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/datasources/note_local_datasource.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/use_cases/create_note_use_case.dart';
import '../../domain/use_cases/delete_note_use_case.dart';
import '../../domain/use_cases/search_notes_use_case.dart';
import '../../domain/use_cases/toggle_archive_use_case.dart';
import '../../domain/use_cases/toggle_pin_use_case.dart';
import '../../domain/use_cases/update_note_use_case.dart';

// Repository provider
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final datasource = NoteLocalDatasource(isar);
  return NoteRepositoryImpl(datasource);
});

// Search query state
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

// Notes list provider
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  late NoteRepository _repository;

  @override
  Future<List<Note>> build() async {
    _repository = ref.watch(noteRepositoryProvider);
    return _repository.getAllNotes();
  }

  Future<void> create(Note note) async {
    try {
      final id = await CreateNoteUseCase(_repository)(note);
      final created = note.copyWith(id: id);
      AppLogger.I.action('notes', 'create', data: {'id': id, 'len': note.body.length});
      state = AsyncData([...?state.valueOrNull?.where((n) => n.isPinned), created, ...?state.valueOrNull?.where((n) => !n.isPinned)]);
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('notes', 'create failed', error: e, stack: s);
      rethrow;
    }
  }

  Future<void> save(Note note) async {
    try {
      await UpdateNoteUseCase(_repository)(note);
      AppLogger.I.action('notes', 'save', data: {'id': note.id});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('notes', 'save failed', error: e, stack: s, data: {'id': note.id});
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await DeleteNoteUseCase(_repository)(id);
      AppLogger.I.action('notes', 'delete', data: {'id': id});
      state = AsyncData(state.valueOrNull?.where((n) => n.id != id).toList() ?? []);
    } catch (e, s) {
      AppLogger.I.error('notes', 'delete failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }

  Future<void> togglePin(int id) async {
    try {
      await TogglePinUseCase(_repository)(id);
      AppLogger.I.action('notes', 'togglePin', data: {'id': id});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('notes', 'togglePin failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }

  Future<void> toggleArchive(int id) async {
    try {
      await ToggleArchiveUseCase(_repository)(id);
      AppLogger.I.action('notes', 'toggleArchive', data: {'id': id});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('notes', 'toggleArchive failed', error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }
}

// Search results provider
final noteSearchResultsProvider = FutureProvider<List<Note>>((ref) {
  final query = ref.watch(noteSearchQueryProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return SearchNotesUseCase(repository)(query);
});
