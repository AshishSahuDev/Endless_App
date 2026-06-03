import 'package:isar/isar.dart';

part 'savings_goal_model.g.dart';

@collection
class SavingsGoalModel {
  Id id = Isar.autoIncrement;
  late String name;
  late double targetAmount;
  double savedAmount = 0;
  DateTime? deadline;
  late DateTime createdAt;
}
