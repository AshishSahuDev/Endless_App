import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/task.dart';
import '../providers/tasks_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_bottom_sheet.dart';

// Tablet breakpoint: 600dp — covers all common Android tablets (7", 8", 10")
// and old phones in landscape. Below 600dp = phone layout.
const _kTabletBreakpoint = 600.0;

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= _kTabletBreakpoint;

    return isTablet ? const _TasksTabletLayout() : const _TasksPhoneLayout();
  }
}

// ─────────────────────────────────────────────
// PHONE LAYOUT  (< 600dp)
// ─────────────────────────────────────────────

class _TasksPhoneLayout extends StatelessWidget {
  const _TasksPhoneLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: const _TasksAppBar(showTabBar: true),
      body: const _TasksList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TABLET LAYOUT  (≥ 600dp) — active | completed side-by-side
// ─────────────────────────────────────────────

class _TasksTabletLayout extends StatelessWidget {
  const _TasksTabletLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Row(
          children: [
            // Left panel — Active
            Expanded(
              child: Scaffold(
                backgroundColor: kBgPrimary,
                appBar: AppBar(
                  backgroundColor: kBgPrimary,
                  elevation: 0,
                  title: const Text(
                    'Active Tasks',
                    style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Iconsax.add_circle, color: kAccentPurple, size: 28),
                      onPressed: () => _showAddSheet(context),
                    ),
                    const SizedBox(width: kSpaceXS),
                  ],
                ),
                body: const _TasksList(forceTab: 0),
              ),
            ),
            // Vertical divider
            Container(width: 1, color: kGlassBorder),
            // Right panel — Completed
            Expanded(
              child: Scaffold(
                backgroundColor: kBgPrimary,
                appBar: AppBar(
                  backgroundColor: kBgPrimary,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: const Text(
                    'Completed',
                    style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
                body: const _TasksList(forceTab: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// App Bar with Active / Completed tab chips
// ─────────────────────────────────────────────

class _TasksAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showTabBar;
  const _TasksAppBar({this.showTabBar = false});

  @override
  Size get preferredSize =>
      Size.fromHeight(showTabBar ? kAppBarHeight + 48 : kAppBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(taskTabProvider);
    return AppBar(
      backgroundColor: kBgPrimary,
      elevation: 0,
      title: const Text(
        kNavTasks,
        style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      bottom: showTabBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kPaddingScreen, 0, kPaddingScreen, kSpaceSM),
                child: Row(
                  children: [
                    _TabChip(label: 'Active', index: 0, currentTab: currentTab),
                    const SizedBox(width: kSpaceSM),
                    _TabChip(label: 'Completed', index: 1, currentTab: currentTab),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _TabChip extends ConsumerWidget {
  final String label;
  final int index;
  final int currentTab;
  const _TabChip({required this.label, required this.index, required this.currentTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = index == currentTab;
    return GestureDetector(
      onTap: () => ref.read(taskTabProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: kSpaceMD, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kAccentPurple : kBgTertiary,
          borderRadius: BorderRadius.circular(kRadiusRound),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : kTextHint,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared task list — drag-to-reorder (active) or static (completed)
// ─────────────────────────────────────────────

class _TasksList extends ConsumerWidget {
  // forceTab is used by the tablet layout to show a specific tab
  // without touching the global taskTabProvider
  final int? forceTab;
  const _TasksList({this.forceTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int tab = forceTab ?? ref.watch(taskTabProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
      error: (_, __) => const Center(
        child: Text(kError, style: TextStyle(color: kTextSecondary)),
      ),
      data: (allTasks) {
        // Filter locally for the tablet forced-tab case
        final tasks = forceTab == null
            ? allTasks
            : allTasks.where((t) => forceTab == 0 ? !t.isCompleted : t.isCompleted).toList();

        if (tasks.isEmpty) return _buildEmpty(tab);

        if (tab == 1 || forceTab == 1) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                kPaddingScreen, kSpaceSM, kPaddingScreen, kSpaceXXL),
            itemCount: tasks.length,
            itemBuilder: (_, i) => TaskCard(
              task: tasks[i],
              onTap: () => _showEditSheet(context, tasks[i]),
            ),
          );
        }

        // Active tasks — drag-to-reorder
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(
              kPaddingScreen, kSpaceSM, kPaddingScreen, kSpaceXXL + kFabSize),
          itemCount: tasks.length,
          onReorderItem: (from, to) {
            ref.read(tasksProvider.notifier).reorder(from, to);
          },
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: child,
          ),
          itemBuilder: (_, i) => TaskCard(
            key: ValueKey(tasks[i].id),
            task: tasks[i],
            onTap: () => _showEditSheet(context, tasks[i]),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(int tab) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab == 0 ? Iconsax.task_square : Iconsax.tick_circle,
            size: 64,
            color: kTextHint,
          ),
          const SizedBox(height: kSpaceMD),
          Text(
            tab == 0
                ? 'No tasks yet.\nTap + to add one.'
                : 'No completed tasks yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextHint, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}

void _showAddSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const TaskBottomSheet(),
  );
}

void _showEditSheet(BuildContext context, Task task) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskBottomSheet(existing: task),
  );
}
