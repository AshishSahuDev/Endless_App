import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

class EndlessApp extends StatelessWidget {
  const EndlessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const SplashScreen(),
    );
  }
}
