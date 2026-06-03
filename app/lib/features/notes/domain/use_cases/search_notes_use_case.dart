import '../entities/note.dart';
import '../repositories/note_repository.dart';

class SearchNotesUseCase {
  final NoteRepository _repository;
  const SearchNotesUseCase(this._repository);

  Future<List<Note>> call(String query) {
    if (query.trim().isEmpty) return _repository.getAllNotes();
    return _repository.searchNotes(query.trim());
  }
}
