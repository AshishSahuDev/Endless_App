import 'package:flutter/material.dart';

class MoneyCategory {
  final String slug;       // unique key: 'food', 'salary', etc.
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const MoneyCategory({
    required this.slug,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
}
