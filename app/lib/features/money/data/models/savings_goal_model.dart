import 'package:isar/isar.dart';
import '../../domain/entities/savings_goal.dart';

part 'savings_goal_model.g.dart';

@collection
class SavingsGoalModel {
  Id id = Isar.autoIncrement;

  late String name;
  late double targetAmount;
  double savedAmount = 0;
  DateTime? deadline;
  late DateTime createdAt;

  SavingsGoal toEntity() => SavingsGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        savedAmount: savedAmount,
        deadline: deadline,
        createdAt: createdAt,
      );

  static SavingsGoalModel fromEntity(SavingsGoal g) => SavingsGoalModel()
    ..id = g.id
    ..name = g.name
    ..targetAmount = g.targetAmount
    ..savedAmount = g.savedAmount
    ..deadline = g.deadline
    ..createdAt = g.createdAt;
}
