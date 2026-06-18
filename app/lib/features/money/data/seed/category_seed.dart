import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/category.dart';

// Default categories — defined in code, never stored in DB.
// Using slugs keeps transaction records stable across reinstalls.
const List<MoneyCategory> kDefaultExpenseCategories = [
  MoneyCategory(slug: 'food',          name: 'Food',         icon: Iconsax.cup,         color: Color(0xFFF59E0B), isExpense: true),
  MoneyCategory(slug: 'transport',     name: 'Transport',    icon: Iconsax.car,         color: Color(0xFF3B82F6), isExpense: true),
  MoneyCategory(slug: 'shopping',      name: 'Shopping',     icon: Iconsax.bag_2,       color: Color(0xFFEC4899), isExpense: true),
  MoneyCategory(slug: 'bills',         name: 'Bills',        icon: Iconsax.receipt_2,   color: Color(0xFFEF4444), isExpense: true),
  MoneyCategory(slug: 'health',        name: 'Health',       icon: Iconsax.heart,       color: Color(0xFF10B981), isExpense: true),
  MoneyCategory(slug: 'entertainment', name: 'Fun',          icon: Iconsax.game,        color: Color(0xFF7C3AED), isExpense: true),
  MoneyCategory(slug: 'education',     name: 'Education',    icon: Iconsax.book_1,      color: Color(0xFF06B6D4), isExpense: true),
  MoneyCategory(slug: 'other_exp',     name: 'Other',        icon: Iconsax.more_circle, color: Color(0xFF6B7280), isExpense: true),
];

const List<MoneyCategory> kDefaultIncomeCategories = [
  MoneyCategory(slug: 'salary',        name: 'Salary',       icon: Iconsax.wallet_3,    color: Color(0xFF10B981), isExpense: false),
  MoneyCategory(slug: 'freelance',     name: 'Freelance',    icon: Iconsax.briefcase,   color: Color(0xFF7C3AED), isExpense: false),
  MoneyCategory(slug: 'business',      name: 'Business',     icon: Iconsax.building_4,  color: Color(0xFF3B82F6), isExpense: false),
  MoneyCategory(slug: 'investment',    name: 'Investment',   icon: Iconsax.chart_2,     color: Color(0xFFF59E0B), isExpense: false),
  MoneyCategory(slug: 'gift',          name: 'Gift',         icon: Iconsax.gift,        color: Color(0xFFEC4899), isExpense: false),
  MoneyCategory(slug: 'other_inc',     name: 'Other',        icon: Iconsax.more_circle, color: Color(0xFF6B7280), isExpense: false),
];

List<MoneyCategory> get allCategories => [
      ...kDefaultExpenseCategories,
      ...kDefaultIncomeCategories,
    ];

MoneyCategory categoryBySlug(String slug) =>
    allCategories.firstWhere((c) => c.slug == slug,
        orElse: () => const MoneyCategory(
              slug: 'other_exp',
              name: 'Other',
              icon: Iconsax.more_circle,
              color: Color(0xFF6B7280),
              isExpense: true,
            ));
