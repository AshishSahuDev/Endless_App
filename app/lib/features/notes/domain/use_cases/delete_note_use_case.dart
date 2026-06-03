import '../repositories/note_repository.dart';

class DeleteNoteUseCase {
  final NoteRepository _repository;
  const DeleteNoteUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteNote(id);
}
