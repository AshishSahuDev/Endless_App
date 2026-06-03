import '../entities/note.dart';

abstract interface class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<List<Note>> getPinnedNotes();
  Future<List<Note>> getArchivedNotes();
  Future<List<Note>> searchNotes(String query);
  Future<Note?> getNoteById(int id);
  Future<int> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
  Future<void> togglePin(int id);
  Future<void> toggleArchive(int id);
}
