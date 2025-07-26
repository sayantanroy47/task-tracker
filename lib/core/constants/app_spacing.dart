/// App spacing and layout constants following the design system
/// Provides consistent spacing throughout the app
class AppSpacing {
  // Base spacing values
  static const double xs = 4.0;   // Extra small - minimal spacing
  static const double sm = 8.0;   // Small - compact spacing
  static const double md = 16.0;  // Medium - default spacing
  static const double lg = 24.0;  // Large - generous spacing
  static const double xl = 32.0;  // Extra large - section spacing
  static const double xxl = 48.0; // Extra extra large - screen spacing
  
  // Component-specific spacing
  static const double cardPadding = md;
  static const double buttonPadding = sm;
  static const double inputPadding = md;
  static const double listItemPadding = md;
  
  // Layout spacing
  static const double screenPadding = md;
  static const double sectionSpacing = lg;
  static const double componentSpacing = md;
  static const double elementSpacing = sm;
  
  // Touch target spacing (minimum 44dp for accessibility)
  static const double minTouchTarget = 44.0;
  static const double touchTargetSpacing = 48.0;
  
  // Gesture areas
  static const double swipeThreshold = 80.0;
  static const double longPressMargin = 8.0;
}

/// App radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;   // Small radius - buttons, chips
  static const double md = 12.0;  // Medium radius - cards, inputs
  static const double lg = 16.0;  // Large radius - modals, sheets
  static const double xl = 24.0;  // Extra large radius - special elements
  static const double circular = 50.0; // Circular - profile pics, FAB
}

/// App elevation constants for Material Design shadows
class AppElevation {
  static const double none = 0.0;    // No shadow
  static const double sm = 1.0;      // Subtle elevation
  static const double md = 4.0;      // Default elevation
  static const double lg = 8.0;      // Prominent elevation
  static const double xl = 16.0;     // High elevation
  static const double fab = 6.0;     // Floating action button
  static const double modal = 24.0;  // Modal dialogs
}

/// Animation duration constants for consistent timing
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Component-specific durations
  static const Duration swipeAnimation = Duration(milliseconds: 200);
  static const Duration taskCompletion = Duration(milliseconds: 300);
  static const Duration voicePulse = Duration(milliseconds: 1000);
  static const Duration cardTransition = Duration(milliseconds: 250);
  static const Duration fabTransition = Duration(milliseconds: 200);
  
  // Loading states
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration rippleDuration = Duration(milliseconds: 200);
}

/// Animation curve constants for smooth motion
class AppCurves {
  static const easeIn = Duration(milliseconds: 100);
  static const easeOut = Duration(milliseconds: 200);
  static const easeInOut = Duration(milliseconds: 300);
  
  // Material motion curves
  static const standardCurve = Duration(milliseconds: 300);
  static const emphasizedCurve = Duration(milliseconds: 500);
}

/// Responsive breakpoints for different screen sizes
class AppBreakpoints {
  static const double mobile = 600.0;   // Mobile phones
  static const double tablet = 960.0;   // Tablets
  static const double desktop = 1280.0; // Desktop screens
  
  // Orientation-specific adjustments
  static const double minPortraitWidth = 320.0;
  static const double minLandscapeHeight = 480.0;
}