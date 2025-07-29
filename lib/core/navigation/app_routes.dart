/// App route paths
class AppRoutes {
  static const String home = '/';
  static const String taskNew = '/task/new';
  static const String taskEdit = '/task/:id/edit';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String voice = '/voice';
  
  // Helper method to build task edit route with ID
  static String taskEditWithId(String taskId) {
    return '/task/$taskId/edit';
  }
}

/// App route names for named navigation
class AppRouteNames {
  static const String home = 'home';
  static const String taskNew = 'task-new';
  static const String taskEdit = 'task-edit';
  static const String calendar = 'calendar';
  static const String settings = 'settings';
  static const String notificationSettings = 'notification-settings';
  static const String voice = 'voice';
}

/// Navigation helper extensions
extension AppNavigation on String {
  /// Check if current route matches this path
  bool isCurrentRoute(String currentRoute) {
    if (this == currentRoute) return true;
    
    // Handle parameterized routes
    if (contains(':')) {
      final pattern = replaceAllMapped(
        RegExp(r':(\w+)'),
        (match) => r'(\w+)',
      );
      return RegExp('^$pattern\$').hasMatch(currentRoute);
    }
    
    return false;
  }
}