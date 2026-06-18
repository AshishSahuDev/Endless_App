import '../entities/savings_goal.dart';

abstract interface class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAllGoals();
  Future<int> createGoal(SavingsGoal goal);
  Future<void> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(int id);
  Future<void> addToSavings(int id, double amount);
}
