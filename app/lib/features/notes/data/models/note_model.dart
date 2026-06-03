import 'package:isar/isar.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String body;
  int colorIndex = 0;
  bool isPinned = false;
  bool isArchived = false;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  Note toEntity() => Note(
        id: id,
        title: title,
        body: body,
        colorIndex: colorIndex,
        isPinned: isPinned,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static NoteModel fromEntity(Note note) => NoteModel()
    ..id = note.id
    ..title = note.title
    ..body = note.body
    ..colorIndex = note.colorIndex
    ..isPinned = note.isPinned
    ..isArchived = note.isArchived
    ..createdAt = note.createdAt
    ..updatedAt = note.updatedAt;
}
