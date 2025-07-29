import 'package:flutter/material.dart';
import 'app_colors.dart';

/// WCAG 2.1 AA compliant color combinations and accessibility utilities
/// Ensures proper color contrast ratios for accessibility
class AccessibilityColors {
  /// WCAG AA minimum contrast ratio (4.5:1 for normal text)
  static const double wcagAANormalText = 4.5;
  
  /// WCAG AA minimum contrast ratio (3:1 for large text)
  static const double wcagAALargeText = 3.0;
  
  /// WCAG AAA enhanced contrast ratio (7:1 for normal text)
  static const double wcagAAANormalText = 7.0;

  /// High contrast color variants for accessibility
  static const Color highContrastBackground = Color(0xFFFFFFFF);  // Pure white
  static const Color highContrastSurface = Color(0xFFF8F9FA);    // Very light gray
  static const Color highContrastText = Color(0xFF000000);       // Pure black
  static const Color highContrastSecondary = Color(0xFF424242);  // Dark gray
  
  /// High contrast dark theme colors
  static const Color highContrastBackgroundDark = Color(0xFF000000);  // Pure black
  static const Color highContrastSurfaceDark = Color(0xFF121212);     // Very dark gray
  static const Color highContrastTextDark = Color(0xFFFFFFFF);        // Pure white
  static const Color highContrastSecondaryDark = Color(0xFFE0E0E0);   // Light gray

  /// Focus indicator colors with high visibility
  static const Color primaryFocus = Color(0xFF2196F3);    // High contrast blue
  static const Color errorFocus = Color(0xFFD32F2F);      // High contrast red
  static const Color successFocus = Color(0xFF388E3C);    // High contrast green
  static const Color warningFocus = Color(0xFFF57C00);    // High contrast orange

  /// Calculate luminance of a color (0.0 to 1.0)
  static double _luminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    double gammaCorrect(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : pow((channel + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * gammaCorrect(r) +
           0.7152 * gammaCorrect(g) +
           0.0722 * gammaCorrect(b);
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color color1, Color color2) {
    final luminance1 = _luminance(color1);
    final luminance2 = _luminance(color2);
    
    final brightest = luminance1 > luminance2 ? luminance1 : luminance2;
    final darkest = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (brightest + 0.05) / (darkest + 0.05);
  }

  /// Check if color combination meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = contrastRatio(foreground, background);
    final requiredRatio = isLargeText ? wcagAALargeText : wcagAANormalText;
    return ratio >= requiredRatio;
  }

  /// Check if color combination meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background) {
    final ratio = contrastRatio(foreground, background);
    return ratio >= wcagAAANormalText;
  }

  /// Get accessible text color for given background
  static Color getAccessibleTextColor(Color background, {bool preferDark = true}) {
    final darkRatio = contrastRatio(Colors.black, background);
    final lightRatio = contrastRatio(Colors.white, background);
    
    if (preferDark && darkRatio >= wcagAANormalText) {
      return Colors.black;
    } else if (lightRatio >= wcagAANormalText) {
      return Colors.white;
    } else {
      // Return the one with better contrast
      return darkRatio > lightRatio ? Colors.black : Colors.white;
    }
  }

  /// Get high contrast variant of a color
  static Color getHighContrastVariant(Color original, Color background) {
    if (meetsWCAGAA(original, background)) {
      return original;
    }
    
    // Try darkening or lightening the color
    final darkerColor = Color.fromRGBO(
      (original.red * 0.7).round().clamp(0, 255),
      (original.green * 0.7).round().clamp(0, 255),
      (original.blue * 0.7).round().clamp(0, 255),
      original.opacity,
    );
    
    final lighterColor = Color.fromRGBO(
      (original.red + (255 - original.red) * 0.3).round().clamp(0, 255),
      (original.green + (255 - original.green) * 0.3).round().clamp(0, 255),
      (original.blue + (255 - original.blue) * 0.3).round().clamp(0, 255),
      original.opacity,
    );
    
    final darkerRatio = contrastRatio(darkerColor, background);
    final lighterRatio = contrastRatio(lighterColor, background);
    
    if (darkerRatio >= wcagAANormalText) {
      return darkerColor;
    } else if (lighterRatio >= wcagAANormalText) {
      return lighterColor;
    } else {
      // Fallback to high contrast colors
      return getAccessibleTextColor(background);
    }
  }

  /// Validate all app colors for WCAG compliance
  static Map<String, AccessibilityColorReport> validateAppColors() {
    final reports = <String, AccessibilityColorReport>{};
    
    // Test primary colors on light backgrounds
    reports['primary_on_light'] = AccessibilityColorReport(
      foreground: AppColors.primary,
      background: AppColors.surface,
      contrastRatio: contrastRatio(AppColors.primary, AppColors.surface),
      meetsAA: meetsWCAGAA(AppColors.primary, AppColors.surface),
      meetsAAA: meetsWCAGAAA(AppColors.primary, AppColors.surface),
    );
    
    // Test text colors
    reports['text_on_surface'] = AccessibilityColorReport(
      foreground: AppColors.onSurface,
      background: AppColors.surface,
      contrastRatio: contrastRatio(AppColors.onSurface, AppColors.surface),
      meetsAA: meetsWCAGAA(AppColors.onSurface, AppColors.surface),
      meetsAAA: meetsWCAGAAA(AppColors.onSurface, AppColors.surface),
    );
    
    // Test category colors
    final categoryColors = [
      ('personal', AppColors.personal),
      ('household', AppColors.household),
      ('work', AppColors.work),
      ('family', AppColors.family),
      ('health', AppColors.health),
      ('finance', AppColors.finance),
    ];
    
    for (final (name, color) in categoryColors) {
      reports['${name}_on_surface'] = AccessibilityColorReport(
        foreground: color,
        background: AppColors.surface,
        contrastRatio: contrastRatio(color, AppColors.surface),
        meetsAA: meetsWCAGAA(color, AppColors.surface),
        meetsAAA: meetsWCAGAAA(color, AppColors.surface),
      );
    }
    
    // Test status colors
    final statusColors = [
      ('success', AppColors.success),
      ('warning', AppColors.warning),
      ('error', AppColors.error),
      ('info', AppColors.info),
    ];
    
    for (final (name, color) in statusColors) {
      reports['${name}_on_surface'] = AccessibilityColorReport(
        foreground: color,
        background: AppColors.surface,
        contrastRatio: contrastRatio(color, AppColors.surface),
        meetsAA: meetsWCAGAA(color, AppColors.surface),
        meetsAAA: meetsWCAGAAA(color, AppColors.surface),
      );
    }
    
    return reports;
  }

  /// Get recommended color fixes for non-compliant combinations
  static Map<String, Color> getColorFixes() {
    final fixes = <String, Color>{};
    final reports = validateAppColors();
    
    for (final entry in reports.entries) {
      final report = entry.value;
      if (!report.meetsAA) {
        fixes[entry.key] = getHighContrastVariant(
          report.foreground,
          report.background,
        );
      }
    }
    
    return fixes;
  }
}

/// Report for color accessibility compliance
class AccessibilityColorReport {
  final Color foreground;
  final Color background;
  final double contrastRatio;
  final bool meetsAA;
  final bool meetsAAA;

  const AccessibilityColorReport({
    required this.foreground,
    required this.background,
    required this.contrastRatio,
    required this.meetsAA,
    required this.meetsAAA,
  });

  @override
  String toString() {
    final compliance = meetsAAA ? 'AAA' : meetsAA ? 'AA' : 'FAIL';
    return 'Contrast: ${contrastRatio.toStringAsFixed(2)}:1 ($compliance)';
  }
}

// Import math for pow function
import 'dart:math';