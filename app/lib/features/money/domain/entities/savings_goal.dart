class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
  bool get isCompleted => savedAmount >= targetAmount;
}
