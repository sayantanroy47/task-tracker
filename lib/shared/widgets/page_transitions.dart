import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

/// Custom page transitions for smooth navigation
/// Provides consistent and polished navigation animations

/// Slide transition from right (default iOS behavior)
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  SlideRightRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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

/// Slide transition from bottom (material modal behavior)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  SlideUpRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;
            
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

/// Fade transition for subtle navigation
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  FadeRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Scale transition for modal dialogs
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  ScaleRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;
            
            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Hero-style transition for detailed views
class HeroRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String heroTag;
  
  HeroRoute({
    required this.child,
    required this.heroTag,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppDurations.medium,
          reverseTransitionDuration: AppDurations.medium,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            
            // Combine slide and scale for dynamic effect
            var slideTween = Tween(
              begin: const Offset(0.3, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve));
            
            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(slideTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: FadeTransition(
                  opacity: animation.drive(fadeTween),
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Utility class for easy access to page transitions
class PageTransitions {
  static Route<T> slideRight<T>(Widget child, [RouteSettings? settings]) {
    return SlideRightRoute<T>(child: child, settings: settings);
  }
  
  static Route<T> slideUp<T>(Widget child, [RouteSettings? settings]) {
    return SlideUpRoute<T>(child: child, settings: settings);
  }
  
  static Route<T> fade<T>(Widget child, [RouteSettings? settings]) {
    return FadeRoute<T>(child: child, settings: settings);
  }
  
  static Route<T> scale<T>(Widget child, [RouteSettings? settings]) {
    return ScaleRoute<T>(child: child, settings: settings);
  }
  
  static Route<T> hero<T>(Widget child, String heroTag, [RouteSettings? settings]) {
    return HeroRoute<T>(child: child, heroTag: heroTag, settings: settings);
  }
}

/// Animation helpers for common UI transitions
class AnimationHelpers {
  /// Create a bouncy animation controller
  static AnimationController createBounceController(TickerProvider vsync) {
    return AnimationController(
      duration: AppDurations.medium,
      vsync: vsync,
    );
  }
  
  /// Create a smooth fade animation
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  /// Create a slide animation
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }
  
  /// Create a scale animation with bounce
  static Animation<double> createBounceScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }
}