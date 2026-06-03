import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDatasource _datasource;
  NoteRepositoryImpl(this._datasource);

  @override
  Future<List<Note>> getAllNotes() async {
    final models = await _datasource.getAllNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Note>> getPinnedNotes() async {
    final models = await _datasource.getPinnedNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Note>> getArchivedNotes() async {
    final models = await _datasource.getArchivedNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final models = await _datasource.searchNotes(query);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final model = await _datasource.getNoteById(id);
    return model?.toEntity();
  }

  @override
  Future<int> createNote(Note note) {
    final model = NoteModel.fromEntity(note);
    return _datasource.putNote(model);
  }

  @override
  Future<void> updateNote(Note note) async {
    final model = NoteModel.fromEntity(note);
    await _datasource.putNote(model);
  }

  @override
  Future<void> deleteNote(int id) => _datasource.deleteNote(id);

  @override
  Future<void> togglePin(int id) async {
    final model = await _datasource.getNoteById(id);
    if (model == null) return;
    model.isPinned = !model.isPinned;
    model.updatedAt = DateTime.now();
    await _datasource.putNote(model);
  }

  @override
  Future<void> toggleArchive(int id) async {
    final model = await _datasource.getNoteById(id);
    if (model == null) return;
    model.isArchived = !model.isArchived;
    model.isPinned = false; // archived notes can't be pinned
    model.updatedAt = DateTime.now();
    await _datasource.putNote(model);
  }
}
