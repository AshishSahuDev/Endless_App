import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_sizes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/presentation/screens/notes_list_screen.dart';
import 'features/tasks/presentation/screens/tasks_screen.dart';
import 'features/reminders/presentation/screens/reminders_screen.dart';
import 'features/alarms/presentation/screens/alarms_screen.dart';
import 'features/money/presentation/screens/money_screen.dart';

class EndlessApp extends StatelessWidget {
  const EndlessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends ConsumerStatefulWidget {
  const _HomeShell();

  @override
  ConsumerState<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<_HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    NotesListScreen(),
    TasksScreen(),
    RemindersScreen(),
    AlarmsScreen(),
    MoneyScreen(),
  ];

  static const _navItems = [
    (icon: Iconsax.note_text, label: kNavNotes),
    (icon: Iconsax.task_square, label: kNavTasks),
    (icon: Iconsax.notification, label: kNavReminders),
    (icon: Iconsax.clock, label: kNavAlarms),
    (icon: Iconsax.money_recive, label: kNavMoney),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kBottomNavHeight,
      decoration: const BoxDecoration(
        color: kBgSecondary,
        border: Border(top: BorderSide(color: kGlassBorder, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) {
          final item = _HomeShellState._navItems[i];
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: kIconMD,
                    color: isActive ? kAccentPurple : kTextHint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? kAccentPurple : kTextHint,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
