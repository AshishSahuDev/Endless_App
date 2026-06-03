import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgPrimary,
      body: Center(
        child: Text('Tasks — Sprint 2 coming soon', style: TextStyle(color: kTextSecondary)),
      ),
    );
  }
}
