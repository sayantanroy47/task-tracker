import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/task_screen.dart';
import '../../features/tasks/task_form_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/voice/voice_screen.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import 'app_routes.dart';
import 'navigation_middleware.dart';

/// Global navigation provider for the app
final routerProvider = Provider<GoRouter>((ref) {
  final middleware = ref.read(navigationMiddlewareProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Use middleware for redirect logic
      return middleware.handleRedirect(state);
    },
    routes: [
      // Shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          // Main task list route
          GoRoute(
            path: AppRoutes.home,
            name: AppRouteNames.home,
            builder: (context, state) => const TaskScreen(),
          ),
          
          // Calendar view route
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRouteNames.calendar,
            builder: (context, state) => const CalendarScreen(),
          ),
          
          // Settings route
          GoRoute(
            path: AppRoutes.settings,
            name: AppRouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // Full-screen routes (without bottom navigation)
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: AppRouteNames.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      
      GoRoute(
        path: AppRoutes.taskNew,
        name: AppRouteNames.taskNew,
        pageBuilder: (context, state) => NavigationTransitions.buildModalTransition(
          state,
          const TaskFormScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.taskEdit,
        name: AppRouteNames.taskEdit,
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['id'] ?? '';
          return NavigationTransitions.buildModalTransition(
            state,
            TaskFormScreen(taskId: taskId),
          );
        },
      ),
      
      GoRoute(
        path: AppRoutes.voice,
        name: AppRouteNames.voice,
        pageBuilder: (context, state) => NavigationTransitions.buildModalTransition(
          state,
          const VoiceScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
});

/// App shell widget that wraps main screens with bottom navigation
class _AppShell extends StatelessWidget {
  final Widget child;
  
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

/// Error screen for navigation errors
class _ErrorScreen extends StatelessWidget {
  final GoException? error;
  
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}