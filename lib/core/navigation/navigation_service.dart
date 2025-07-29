import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';

/// Navigation service provider for programmatic navigation
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

/// Service for handling app navigation
class NavigationService {
  /// Navigate to home screen
  void goHome(BuildContext context) {
    context.go(AppRoutes.home);
  }
  
  /// Navigate to task creation screen
  void goToTaskCreation(BuildContext context) {
    context.go(AppRoutes.taskNew);
  }
  
  /// Navigate to task editing screen
  void goToTaskEdit(BuildContext context, String taskId) {
    context.go(AppRoutes.taskEditWithId(taskId));
  }
  
  /// Navigate to calendar screen
  void goToCalendar(BuildContext context) {
    context.go(AppRoutes.calendar);
  }
  
  /// Navigate to settings screen
  void goToSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }
  
  /// Navigate to voice input screen
  void goToVoice(BuildContext context) {
    context.go(AppRoutes.voice);
  }
  
  /// Push a new route (for modal-style navigation)
  void pushTaskCreation(BuildContext context) {
    context.push(AppRoutes.taskNew);
  }
  
  /// Push task edit route
  void pushTaskEdit(BuildContext context, String taskId) {
    context.push(AppRoutes.taskEditWithId(taskId));
  }
  
  /// Push voice input screen (modal-style)
  void pushVoice(BuildContext context) {
    context.push(AppRoutes.voice);
  }
  
  /// Go back to previous screen
  void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // If can't pop, go to home
      context.go(AppRoutes.home);
    }
  }
  
  /// Replace current route
  void replaceWithHome(BuildContext context) {
    context.pushReplacement(AppRoutes.home);
  }
  
  /// Clear navigation stack and go to home
  void clearAndGoHome(BuildContext context) {
    while (context.canPop()) {
      context.pop();
    }
    context.go(AppRoutes.home);
  }
  
  /// Get current route path
  String? getCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    return router.routerDelegate.currentConfiguration.uri.path;
  }
  
  /// Check if we're on a specific route
  bool isOnRoute(BuildContext context, String route) {
    final currentRoute = getCurrentRoute(context);
    return route.isCurrentRoute(currentRoute ?? '');
  }
}