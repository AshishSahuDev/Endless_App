import 'package:isar/isar.dart';
import '../models/savings_goal_model.dart';
import '../../../../core/errors/app_exceptions.dart';

class SavingsGoalLocalDatasource {
  final Isar _isar;
  SavingsGoalLocalDatasource(this._isar);

  Future<List<SavingsGoalModel>> getAllGoals() async {
    try {
      return _isar.savingsGoalModels.where().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load savings goals', cause: e);
    }
  }

  Future<SavingsGoalModel?> getGoalById(int id) async {
    try {
      return _isar.savingsGoalModels.get(id);
    } on IsarError catch (e) {
      throw DatabaseException('Failed to get goal', cause: e);
    }
  }

  Future<int> putGoal(SavingsGoalModel model) async {
    try {
      return _isar.writeTxn(() => _isar.savingsGoalModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save goal', cause: e);
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      await _isar.writeTxn(() => _isar.savingsGoalModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete goal', cause: e);
    }
  }
}
