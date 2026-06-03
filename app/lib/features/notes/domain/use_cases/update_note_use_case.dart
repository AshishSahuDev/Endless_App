import '../entities/note.dart';
import '../repositories/note_repository.dart';

class UpdateNoteUseCase {
  final NoteRepository _repository;
  const UpdateNoteUseCase(this._repository);

  Future<void> call(Note note) => _repository.updateNote(note);
}
