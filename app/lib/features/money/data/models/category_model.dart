import 'package:isar/isar.dart';

part 'category_model.g.dart';

// Stored only for user-created custom categories.
// Default categories are defined in category_seed.dart (code-only, no DB).
@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String slug;

  late String name;
  late String iconCodePoint; // MaterialIconData codePoint as hex string
  late int colorValue;       // ARGB int
  bool isExpense = true;
}
