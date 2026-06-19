import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../../features/alarms/presentation/screens/alarms_screen.dart';
import '../../features/money/presentation/screens/money_screen.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    NotesListScreen(),
    TasksScreen(),
    RemindersScreen(),
    AlarmsScreen(),
    MoneyScreen(),
  ];

  void _onNavTap(int i) {
    if (i == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Iconsax.note_text, label: kNavNotes),
    (icon: Iconsax.task_square, label: kNavTasks),
    (icon: Iconsax.notification, label: kNavReminders),
    (icon: Iconsax.clock, label: kNavAlarms),
    (icon: Iconsax.money_recive, label: kNavMoney),
  ];

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
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? kAccentPurple.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      item.icon,
                      size: kIconMD,
                      color: isActive ? kAccentPurple : kTextHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? kAccentPurple : kTextHint,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
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
