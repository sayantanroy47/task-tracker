import 'package:flutter/material.dart';

/// App color palette following the design system specifications
/// Optimized for forgetful users with high contrast and clear differentiation
class AppColors {
  // Primary colors - calm and friendly
  static const primary = Color(0xFF6366F1);      // Soft indigo
  static const primaryLight = Color(0xFF8B8CF7); // Light indigo
  static const primaryDark = Color(0xFF4F46E5);  // Dark indigo
  
  // Background colors - Light theme
  static const background = Color(0xFFFAFAFA);   // Off-white
  static const surface = Color(0xFFFFFFFF);      // Pure white
  static const surfaceVariant = Color(0xFFF5F5F5); // Light gray
  
  // Background colors - Dark theme
  static const backgroundDark = Color(0xFF1A1A1A);   // Dark gray
  static const surfaceDark = Color(0xFF2D2D2D);      // Medium dark gray
  static const surfaceVariantDark = Color(0xFF404040); // Light dark gray
  
  // Text colors - Light theme
  static const onBackground = Color(0xFF1F1F1F);  // Near black
  static const onSurface = Color(0xFF424242);     // Dark gray
  static const onSurfaceVariant = Color(0xFF757575); // Medium gray
  
  // Text colors - Dark theme
  static const onBackgroundDark = Color(0xFFE0E0E0);  // Light gray
  static const onSurfaceDark = Color(0xFFBDBDBD);     // Medium light gray
  static const onSurfaceVariantDark = Color(0xFF9E9E9E); // Medium gray
  
  // Category colors - vibrant and accessible
  static const personal = Color(0xFF2196F3);      // Blue
  static const household = Color(0xFF4CAF50);     // Green
  static const work = Color(0xFFFF9800);          // Orange
  static const family = Color(0xFFE91E63);        // Pink
  static const health = Color(0xFF9C27B0);        // Purple
  static const finance = Color(0xFFFFC107);       // Amber
  
  // Status colors
  static const success = Color(0xFF4CAF50);       // Green
  static const warning = Color(0xFFFF9800);       // Orange
  static const error = Color(0xFFF44336);         // Red
  static const info = Color(0xFF2196F3);          // Blue
  
  // Functional colors
  static const disabled = Color(0xFFBDBDBD);      // Light gray
  static const divider = Color(0xFFE0E0E0);       // Very light gray
  static const shadow = Color(0x1A000000);        // Black with 10% opacity
  
  // Voice input colors
  static const voiceActive = Color(0xFF4CAF50);   // Green when recording
  static const voiceProcessing = Color(0xFFFF9800); // Orange when processing
  static const voiceInactive = Color(0xFF9E9E9E); // Gray when inactive
  
  /// Get category color by category name
  static Color getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'personal':
        return personal;
      case 'household':
        return household;
      case 'work':
        return work;
      case 'family':
        return family;
      case 'health':
        return health;
      case 'finance':
        return finance;
      default:
        return primary;
    }
  }
  
  /// Get a lighter version of any color for disabled states
  static Color getLightVariant(Color color) {
    return color.withOpacity(0.3);
  }
  
  /// Get a darker version of any color for pressed states
  static Color getDarkVariant(Color color) {
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1.0,
    );
  }
}