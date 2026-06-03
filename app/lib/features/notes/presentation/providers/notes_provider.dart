import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
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
    final id = await CreateNoteUseCase(_repository)(note);
    final created = note.copyWith(id: id);
    state = AsyncData([...?state.valueOrNull?.where((n) => n.isPinned), created, ...?state.valueOrNull?.where((n) => !n.isPinned)]);
    ref.invalidateSelf();
  }

  Future<void> save(Note note) async {
    await UpdateNoteUseCase(_repository)(note);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DeleteNoteUseCase(_repository)(id);
    state = AsyncData(state.valueOrNull?.where((n) => n.id != id).toList() ?? []);
  }

  Future<void> togglePin(int id) async {
    await TogglePinUseCase(_repository)(id);
    ref.invalidateSelf();
  }

  Future<void> toggleArchive(int id) async {
    await ToggleArchiveUseCase(_repository)(id);
    ref.invalidateSelf();
  }
}

// Search results provider
final noteSearchResultsProvider = FutureProvider<List<Note>>((ref) {
  final query = ref.watch(noteSearchQueryProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return SearchNotesUseCase(repository)(query);
});
