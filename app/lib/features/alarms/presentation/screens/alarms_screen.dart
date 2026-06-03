import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgPrimary,
      body: Center(
        child: Text('Alarms — Sprint 3 coming soon', style: TextStyle(color: kTextSecondary)),
      ),
    );
  }
}
