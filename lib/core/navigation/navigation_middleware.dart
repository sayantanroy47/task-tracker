import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Navigation middleware provider for handling navigation guards and analytics
final navigationMiddlewareProvider = Provider<NavigationMiddleware>((ref) {
  return NavigationMiddleware(ref);
});

/// Middleware for navigation events and guards
class NavigationMiddleware {
  final Ref _ref;
  
  NavigationMiddleware(this._ref);

  /// Handle global navigation redirects and guards
  String? handleRedirect(GoRouterState state) {
    final currentPath = state.uri.path;
    
    // Add navigation guards here
    // Example: Check if user is onboarded
    // if (!_ref.read(isOnboardedProvider) && currentPath != AppRoutes.onboarding) {
    //   return AppRoutes.onboarding;
    // }
    
    // Example: Redirect from legacy routes
    if (currentPath == '/tasks') {
      return AppRoutes.home;
    }
    
    // Log navigation for analytics (only in debug mode)
    if (kDebugMode) {
      debugPrint('Navigation: ${state.uri}');
    }
    
    return null; // No redirect needed
  }

  /// Handle deep link validation
  bool validateDeepLink(GoRouterState state) {
    final path = state.uri.path;
    final pathSegments = state.pathParameters;
    
    // Validate task edit routes have valid IDs
    if (path.startsWith('/task/') && path.endsWith('/edit')) {
      final taskId = pathSegments['id'];
      if (taskId == null || taskId.isEmpty) {
        return false;
      }
      // Additional validation could check if task exists
    }
    
    return true;
  }

  /// Handle navigation analytics and logging
  void logNavigation(GoRouterState state) {
    if (kDebugMode) {
      debugPrint('Navigation Event: ${state.uri.path}');
      if (state.pathParameters.isNotEmpty) {
        debugPrint('Parameters: ${state.pathParameters}');
      }
      if (state.uri.queryParameters.isNotEmpty) {
        debugPrint('Query Parameters: ${state.uri.queryParameters}');
      }
    }
    
    // Here you could integrate with analytics services like Firebase Analytics
    // _analyticsService.logScreenView(screenName: state.name);
  }

  /// Handle navigation errors
  void handleNavigationError(Exception error, GoRouterState state) {
    if (kDebugMode) {
      debugPrint('Navigation Error: $error');
      debugPrint('Attempted route: ${state.uri}');
    }
    
    // Here you could log errors to crash reporting services
    // _crashReportingService.recordError(error, stackTrace);
  }
}

/// Provider for current route information
final currentRouteProvider = StateProvider<String>((ref) => AppRoutes.home);

/// Provider for navigation history
final navigationHistoryProvider = StateProvider<List<String>>((ref) => []);

/// Extension to help with route matching and validation
extension RouteValidation on String {
  /// Check if route is a main tab route (has bottom navigation)
  bool get isMainTabRoute {
    return this == AppRoutes.home ||
           this == AppRoutes.calendar ||
           this == AppRoutes.settings;
  }
  
  /// Check if route is a full-screen modal route
  bool get isModalRoute {
    return this == AppRoutes.taskNew ||
           this == AppRoutes.voice ||
           startsWith('/task/') && endsWith('/edit');
  }
  
  /// Extract task ID from task edit route
  String? get taskIdFromRoute {
    if (!startsWith('/task/') || !endsWith('/edit')) return null;
    
    final segments = split('/');
    if (segments.length >= 3) {
      return segments[2];
    }
    return null;
  }
}

/// Navigation transition configuration
class NavigationTransitions {
  /// Default page transition for main routes
  static Page<T> buildMainTransition<T extends Object?>(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  /// Slide transition for modal routes
  static Page<T> buildModalTransition<T extends Object?>(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}