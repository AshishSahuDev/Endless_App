import 'package:isar/isar.dart';

part 'category_model.g.dart';

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;
  late String name;
  late String iconName;
  late int colorValue;
  bool isExpense = true;
  bool isDefault = false;
}
