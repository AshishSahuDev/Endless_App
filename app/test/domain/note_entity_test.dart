import 'package:flutter_test/flutter_test.dart';
import 'package:endless/features/notes/domain/entities/note.dart';

Note _note({String title = '', String body = ''}) => Note(
      id: 1,
      title: title,
      body: body,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

void main() {
  group('Note.isEmpty', () {
    test('true when both title and body are blank', () {
      expect(_note().isEmpty, isTrue);
    });

    test('true when only whitespace', () {
      expect(_note(title: '   ', body: '\n').isEmpty, isTrue);
    });

    test('false when title has content', () {
      expect(_note(title: 'Hello').isEmpty, isFalse);
    });

    test('false when body has content', () {
      expect(_note(body: 'Some text').isEmpty, isFalse);
    });
  });

  group('Note.copyWith', () {
    final original = Note(
      id: 1,
      title: 'Original',
      body: 'Body',
      isPinned: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('changes title', () {
      final copy = original.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(copy.body, original.body);
      expect(copy.id, original.id);
    });

    test('pins the note', () {
      final pinned = original.copyWith(isPinned: true);
      expect(pinned.isPinned, isTrue);
      expect(original.isPinned, isFalse);
    });

    test('archives the note', () {
      final archived = original.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
    });

    test('changes color index', () {
      final colored = original.copyWith(colorIndex: 3);
      expect(colored.colorIndex, 3);
    });

    test('does not mutate original', () {
      original.copyWith(title: 'Changed', isPinned: true);
      expect(original.title, 'Original');
      expect(original.isPinned, isFalse);
    });
  });
}
