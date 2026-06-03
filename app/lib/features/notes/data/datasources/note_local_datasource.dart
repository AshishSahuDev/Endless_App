import 'package:isar/isar.dart';
import '../models/note_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class NoteLocalDatasource {
  final Isar _isar;
  NoteLocalDatasource(this._isar);

  Future<List<NoteModel>> getAllNotes() async {
    try {
      return _isar.noteModels
          .filter()
          .isArchivedEqualTo(false)
          .sortByIsPinnedDesc()
          .thenByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load notes', cause: e);
    }
  }

  Future<List<NoteModel>> getPinnedNotes() async {
    try {
      return _isar.noteModels
          .filter()
          .isPinnedEqualTo(true)
          .isArchivedEqualTo(false)
          .sortByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load pinned notes', cause: e);
    }
  }

  Future<List<NoteModel>> getArchivedNotes() async {
    try {
      return _isar.noteModels
          .filter()
          .isArchivedEqualTo(true)
          .sortByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load archived notes', cause: e);
    }
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final lower = query.toLowerCase();
      return _isar.noteModels
          .filter()
          .isArchivedEqualTo(false)
          .group((q) => q
              .titleContains(lower, caseSensitive: false)
              .or()
              .bodyContains(lower, caseSensitive: false))
          .sortByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Search failed', cause: e);
    }
  }

  Future<NoteModel?> getNoteById(int id) async {
    try {
      return _isar.noteModels.get(id);
    } on IsarError catch (e) {
      throw DatabaseException('Failed to get note', cause: e);
    }
  }

  Future<int> putNote(NoteModel model) async {
    try {
      return _isar.writeTxn(() => _isar.noteModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save note', cause: e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _isar.writeTxn(() => _isar.noteModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete note', cause: e);
    }
  }
}
