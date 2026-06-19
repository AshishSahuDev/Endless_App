import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seen ? const HomeShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo box
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kAccentPurple, kAccentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kAccentPurple.withAlpha(100),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.all_inclusive_rounded,
                color: Colors.white,
                size: 52,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.75, 0.75),
                  end: const Offset(1.0, 1.0),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 24),

            // App name
            const Text(
              'Endless',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
              ),
            )
                .animate(delay: 350.ms)
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'One app. Everything you need.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
