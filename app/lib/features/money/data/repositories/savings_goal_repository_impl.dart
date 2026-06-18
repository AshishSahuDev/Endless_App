import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../datasources/savings_goal_local_datasource.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final SavingsGoalLocalDatasource _datasource;
  SavingsGoalRepositoryImpl(this._datasource);

  @override
  Future<List<SavingsGoal>> getAllGoals() async {
    final models = await _datasource.getAllGoals();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> createGoal(SavingsGoal goal) {
    return _datasource.putGoal(SavingsGoalModel.fromEntity(goal));
  }

  @override
  Future<void> updateGoal(SavingsGoal goal) async {
    await _datasource.putGoal(SavingsGoalModel.fromEntity(goal));
  }

  @override
  Future<void> deleteGoal(int id) => _datasource.deleteGoal(id);

  @override
  Future<void> addToSavings(int id, double amount) async {
    final model = await _datasource.getGoalById(id);
    if (model == null) return;
    model.savedAmount = (model.savedAmount + amount).clamp(0, model.targetAmount);
    await _datasource.putGoal(model);
  }
}
