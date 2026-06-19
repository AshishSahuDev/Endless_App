import 'package:flutter_test/flutter_test.dart';
import 'package:endless/features/tasks/domain/entities/task.dart';

void main() {
  group('Task.isOverdue', () {
    final past = DateTime.now().subtract(const Duration(days: 1));
    final future = DateTime.now().add(const Duration(days: 1));
    final base = DateTime.now();

    Task make({bool completed = false, DateTime? due}) => Task(
          id: 1,
          title: 'Test',
          isCompleted: completed,
          dueDate: due,
          createdAt: base,
          updatedAt: base,
        );

    test('overdue when past due and not completed', () {
      expect(make(due: past).isOverdue, isTrue);
    });

    test('not overdue when completed even if past due', () {
      expect(make(completed: true, due: past).isOverdue, isFalse);
    });

    test('not overdue when due date is in the future', () {
      expect(make(due: future).isOverdue, isFalse);
    });

    test('not overdue when no due date', () {
      expect(make().isOverdue, isFalse);
    });
  });

  group('Task.copyWith', () {
    final base = DateTime(2024, 1, 1);
    final original = Task(
      id: 1,
      title: 'Buy milk',
      priority: Priority.low,
      createdAt: base,
      updatedAt: base,
    );

    test('copies with new title', () {
      final copy = original.copyWith(title: 'Buy bread');
      expect(copy.title, 'Buy bread');
      expect(copy.id, original.id);
    });

    test('copies with new priority', () {
      final copy = original.copyWith(priority: Priority.high);
      expect(copy.priority, Priority.high);
    });

    test('copies completion status', () {
      final copy = original.copyWith(isCompleted: true);
      expect(copy.isCompleted, isTrue);
      expect(original.isCompleted, isFalse);
    });
  });

  group('Priority enum', () {
    test('all three values exist', () {
      expect(Priority.values, containsAll([Priority.low, Priority.medium, Priority.high]));
    });
  });
}
