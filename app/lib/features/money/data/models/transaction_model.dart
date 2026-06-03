import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;
  late double amount;
  bool isExpense = true;
  late String categoryId;
  String? note;

  @Index()
  late DateTime date;

  late DateTime createdAt;
}
