import '../repositories/note_repository.dart';

class ToggleArchiveUseCase {
  final NoteRepository _repository;
  const ToggleArchiveUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleArchive(id);
}
