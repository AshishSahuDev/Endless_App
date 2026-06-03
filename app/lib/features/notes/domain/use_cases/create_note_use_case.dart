import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/errors/app_exceptions.dart';

class CreateNoteUseCase {
  final NoteRepository _repository;
  const CreateNoteUseCase(this._repository);

  Future<int> call(Note note) async {
    if (note.isEmpty) throw const ValidationException('Note cannot be empty');
    return _repository.createNote(note);
  }
}
