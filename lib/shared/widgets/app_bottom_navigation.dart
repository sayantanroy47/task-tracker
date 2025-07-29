import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/navigation/navigation_service.dart';

/// Bottom navigation bar for the app
class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    final currentRoute = navigationService.getCurrentRoute(context) ?? '/';
    
    // Determine current index based on route
    int currentIndex = _getIndexFromRoute(currentRoute);
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.list),
          selectedIcon: Icon(Icons.list),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
  
  int _getIndexFromRoute(String route) {
    if (route.startsWith('/calendar')) return 1;
    if (route.startsWith('/settings')) return 2;
    return 0; // Default to tasks
  }
  
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.calendar);
        break;
      case 2:
        context.go(AppRoutes.settings);
        break;
    }
  }
}