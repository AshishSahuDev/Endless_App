enum RecurringInterval { none, daily, weekly, monthly }

class Reminder {
  final int id;
  final String title;
  final String? note;
  final DateTime reminderAt;
  final RecurringInterval recurring;
  final bool isTriggered;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.reminderAt,
    this.recurring = RecurringInterval.none,
    this.isTriggered = false,
    required this.createdAt,
  });

  Reminder copyWith({
    int? id,
    String? title,
    String? note,
    DateTime? reminderAt,
    RecurringInterval? recurring,
    bool? isTriggered,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      reminderAt: reminderAt ?? this.reminderAt,
      recurring: recurring ?? this.recurring,
      isTriggered: isTriggered ?? this.isTriggered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUpcoming => !isTriggered && reminderAt.isAfter(DateTime.now());
  bool get isPast => reminderAt.isBefore(DateTime.now()) && !isTriggered;
}
