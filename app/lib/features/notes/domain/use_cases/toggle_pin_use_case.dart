import '../repositories/note_repository.dart';

class TogglePinUseCase {
  final NoteRepository _repository;
  const TogglePinUseCase(this._repository);

  Future<void> call(int id) => _repository.togglePin(id);
}
