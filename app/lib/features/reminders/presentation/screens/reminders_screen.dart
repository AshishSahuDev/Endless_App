import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgPrimary,
      body: Center(
        child: Text('Reminders — Sprint 3 coming soon', style: TextStyle(color: kTextSecondary)),
      ),
    );
  }
}
