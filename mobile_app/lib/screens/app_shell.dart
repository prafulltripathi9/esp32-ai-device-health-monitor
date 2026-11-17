import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'dashboard/dashboard_screen.dart';
import 'devices/devices_screen.dart';
import 'insights/ai_insights_screen.dart';
import 'settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  final List<String> titles = [
    'Dashboard',
    'Devices',
    'AI Insights',
    'Settings',
  ];

  final List<IconData> icons = [
    Icons.dashboard_outlined,
    Icons.devices_outlined,
    Icons.analytics_outlined,
    Icons.settings_outlined,
  ];

final List<Widget> pages = [
  const DashboardScreen(),
  const DevicesScreen(),
  const AiInsightsScreen(),
  const SettingsScreen(),
];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primary,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.textSecondary,
                  ),
                  destinations: List.generate(
                    titles.length,
                    (index) => NavigationRailDestination(
                      icon: Icon(icons[index]),
                      label: Text(titles[index]),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: AppColors.border,
                ),
                Expanded(
                  child: pages[selectedIndex],
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.surface,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: List.generate(
              titles.length,
              (index) => NavigationDestination(
                icon: Icon(icons[index]),
                label: titles[index],
              ),
            ),
          ),
        );
      },
    );
  }
}