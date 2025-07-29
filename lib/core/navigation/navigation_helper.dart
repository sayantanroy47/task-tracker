import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Navigation helper class with utility methods for common navigation patterns
class NavigationHelper {
  NavigationHelper._();

  /// Navigate to home and clear navigation stack
  static void goHome(BuildContext context, {bool clearStack = false}) {
    if (clearStack) {
      while (context.canPop()) {
        context.pop();
      }
    }
    context.go(AppRoutes.home);
  }

  /// Navigate to task creation with optional pre-filled data
  static void createTask(BuildContext context, {
    String? title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    bool push = true,
  }) {
    final uri = Uri(
      path: AppRoutes.taskNew,
      queryParameters: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (categoryId != null) 'categoryId': categoryId,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
    );

    if (push) {
      context.push(uri.toString());
    } else {
      context.go(uri.toString());
    }
  }

  /// Navigate to task editing
  static void editTask(BuildContext context, String taskId, {bool push = true}) {
    final route = AppRoutes.taskEditWithId(taskId);
    if (push) {
      context.push(route);
    } else {
      context.go(route);
    }
  }

  /// Navigate to voice input
  static void openVoiceInput(BuildContext context, {bool push = true}) {
    if (push) {
      context.push(AppRoutes.voice);
    } else {
      context.go(AppRoutes.voice);
    }
  }

  /// Navigate to calendar with optional date
  static void openCalendar(BuildContext context, {DateTime? focusDate}) {
    final uri = Uri(
      path: AppRoutes.calendar,
      queryParameters: {
        if (focusDate != null) 'date': focusDate.toIso8601String(),
      },
    );
    context.go(uri.toString());
  }

  /// Navigate to settings with optional section
  static void openSettings(BuildContext context, {String? section}) {
    final uri = Uri(
      path: AppRoutes.settings,
      queryParameters: {
        if (section != null) 'section': section,
      },
    );
    context.go(uri.toString());
  }

  /// Show confirmation dialog before navigation
  static Future<bool> confirmNavigation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Continue',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Navigate back with optional fallback route
  static void goBack(BuildContext context, {String? fallbackRoute}) {
    if (context.canPop()) {
      context.pop();
    } else if (fallbackRoute != null) {
      context.go(fallbackRoute);
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Handle deep link navigation
  static void handleDeepLink(BuildContext context, String link) {
    try {
      final uri = Uri.parse(link);
      
      // Handle different deep link patterns
      if (uri.scheme == 'tasktracker') {
        _handleTaskTrackerDeepLink(context, uri);
      } else if (uri.scheme == 'https' && uri.host == 'tasktracker.app') {
        _handleWebDeepLink(context, uri);
      } else {
        // Default to home for unknown links
        context.go(AppRoutes.home);
      }
    } catch (e) {
      // Invalid link format, go to home
      context.go(AppRoutes.home);
    }
  }

  /// Handle tasktracker:// scheme deep links
  static void _handleTaskTrackerDeepLink(BuildContext context, Uri uri) {
    final path = uri.path;
    final query = uri.queryParameters;
    
    switch (path) {
      case '/task/new':
        createTask(
          context,
          title: query['title'],
          description: query['description'],
          categoryId: query['categoryId'],
          dueDate: query['dueDate'] != null 
              ? DateTime.tryParse(query['dueDate']!) 
              : null,
        );
        break;
      case '/voice':
        openVoiceInput(context);
        break;
      case '/calendar':
        openCalendar(
          context,
          focusDate: query['date'] != null 
              ? DateTime.tryParse(query['date']!) 
              : null,
        );
        break;
      case '/settings':
        openSettings(context, section: query['section']);
        break;
      default:
        if (path.startsWith('/task/') && path.endsWith('/edit')) {
          final taskId = path.split('/')[2];
          editTask(context, taskId);
        } else {
          context.go(AppRoutes.home);
        }
    }
  }

  /// Handle https://tasktracker.app deep links
  static void _handleWebDeepLink(BuildContext context, Uri uri) {
    // Convert web URLs to app routes
    final path = uri.path;
    
    if (path.startsWith('/app')) {
      // Remove /app prefix and handle as app route
      final appPath = path.substring(4);
      context.go(appPath.isEmpty ? AppRoutes.home : appPath);
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// Generate shareable deep link
  static String generateDeepLink({
    required String route,
    Map<String, String>? parameters,
  }) {
    final uri = Uri(
      scheme: 'tasktracker',
      path: route,
      queryParameters: parameters,
    );
    return uri.toString();
  }

  /// Generate web-compatible deep link
  static String generateWebLink({
    required String route,
    Map<String, String>? parameters,
  }) {
    final uri = Uri(
      scheme: 'https',
      host: 'tasktracker.app',
      path: '/app$route',
      queryParameters: parameters,
    );
    return uri.toString();
  }

  /// Check if current route matches pattern
  static bool isCurrentRoute(BuildContext context, String routePattern) {
    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    return routePattern.isCurrentRoute(currentPath);
  }

  /// Get current route path
  static String getCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  /// Get route parameters from current context
  static Map<String, String> getCurrentParameters(BuildContext context) {
    final router = GoRouter.of(context);
    final state = router.routerDelegate.currentConfiguration;
    return state.pathParameters;
  }

  /// Get query parameters from current context
  static Map<String, String> getCurrentQueryParameters(BuildContext context) {
    final router = GoRouter.of(context);
    final state = router.routerDelegate.currentConfiguration;
    return state.uri.queryParameters;
  }
}