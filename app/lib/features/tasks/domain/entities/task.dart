enum Priority { low, medium, high }

class Task {
  final int id;
  final String title;
  final String? note;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.note,
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.dueDate,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? note,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}
