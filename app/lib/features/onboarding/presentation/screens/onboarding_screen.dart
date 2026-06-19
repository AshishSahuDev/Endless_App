import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Iconsax.note_text,
      gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      title: 'Capture Everything',
      subtitle:
          'Color-coded notes, pinned ideas, and powerful search — all stored offline on your device.',
    ),
    _Slide(
      icon: Iconsax.task_square,
      gradient: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      title: 'Stay on Track',
      subtitle:
          'Tasks with priorities, smart reminders, and alarms that actually get you moving.',
    ),
    _Slide(
      icon: Iconsax.money_recive,
      gradient: [Color(0xFF064E3B), Color(0xFF10B981)],
      title: 'Money, Simplified',
      subtitle:
          'Track income and spending, set savings goals, and see exactly where it all goes.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: isLast ? null : _skip,
                child: Text(
                  isLast ? '' : 'Skip',
                  style: const TextStyle(color: kTextSecondary, fontSize: 14),
                ),
              ),
            ),

            // Slide content
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final isActive = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? slide.gradient.last : kTextHint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: slide.gradient.last,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.gradient.last.withAlpha(80),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(slide.icon, color: Colors.white, size: 52),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  const _Slide({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}
