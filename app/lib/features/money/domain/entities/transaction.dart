class MoneyTransaction {
  final int id;
  final double amount;
  final bool isExpense;
  final String categorySlug;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const MoneyTransaction({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.categorySlug,
    this.note,
    required this.date,
    required this.createdAt,
  });

  MoneyTransaction copyWith({
    int? id,
    double? amount,
    bool? isExpense,
    String? categorySlug,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      categorySlug: categorySlug ?? this.categorySlug,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
