import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Cockpit', path: '/'),
    _Tab(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Jobs', path: '/jobs'),
    _Tab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Calendrier', path: '/calendar'),
    _Tab(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Stats', path: '/stats'),
    _Tab(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Clients', path: '/clients'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => t.path == location);
    final currentIndex = idx < 0 ? 0 : idx;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(tab.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
