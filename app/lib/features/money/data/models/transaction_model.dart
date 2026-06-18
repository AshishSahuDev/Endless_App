import 'package:isar/isar.dart';
import '../../domain/entities/transaction.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  late double amount;
  bool isExpense = true;

  @Index()
  late String categorySlug;

  String? note;

  @Index()
  late DateTime date;

  late DateTime createdAt;

  MoneyTransaction toEntity() => MoneyTransaction(
        id: id,
        amount: amount,
        isExpense: isExpense,
        categorySlug: categorySlug,
        note: note,
        date: date,
        createdAt: createdAt,
      );

  static TransactionModel fromEntity(MoneyTransaction tx) => TransactionModel()
    ..id = tx.id
    ..amount = tx.amount
    ..isExpense = tx.isExpense
    ..categorySlug = tx.categorySlug
    ..note = tx.note
    ..date = tx.date
    ..createdAt = tx.createdAt;
}
