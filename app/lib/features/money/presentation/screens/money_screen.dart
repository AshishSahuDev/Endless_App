import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgPrimary,
      body: Center(
        child: Text('Money Manager — Sprint 4 coming soon', style: TextStyle(color: kTextSecondary)),
      ),
    );
  }
}
