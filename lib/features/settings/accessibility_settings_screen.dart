import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/services/accessibility_service.dart';
import '../../core/constants/accessibility_colors.dart';

/// Comprehensive accessibility settings screen
/// Allows users to customize accessibility preferences
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  late AccessibilityService _accessibilityService;
  late AccessibilityPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
    _preferences = _accessibilityService.preferences;
  }

  void _updatePreferences(AccessibilityPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
    });
    _accessibilityService.updatePreferences(newPreferences);
    _accessibilityService.announce('Settings updated');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to settings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Visual Accessibility Section
          _buildSectionHeader('Visual Accessibility'),
          _buildSettingCard(
            icon: Icons.contrast,
            title: 'High Contrast Mode',
            subtitle: 'Enhance color contrast for better visibility',
            child: Switch(
              value: _preferences.forceHighContrast,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(
                    _preferences.copyWith(forceHighContrast: value));
              },
            ),
          ),

          _buildSettingCard(
            icon: Icons.text_fields,
            title: 'Large Text',
            subtitle: 'Increase text size throughout the app',
            child: Switch(
              value: _preferences.largeText,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(_preferences.copyWith(largeText: value));
              },
            ),
          ),

          if (_preferences.largeText) ...[
            _buildSettingCard(
              icon: Icons.format_size,
              title: 'Text Scale Factor',
              subtitle: 'Adjust how much larger text should be',
              child: Column(
                children: [
                  Slider(
                    value: _preferences.textScaleFactor,
                    min: 1.0,
                    max: 2.5,
                    divisions: 15,
                    label: '${(_preferences.textScaleFactor * 100).round()}%',
                    onChanged: (value) {
                      _updatePreferences(
                          _preferences.copyWith(textScaleFactor: value));
                    },
                  ),
                  Text(
                    'Sample text at ${(_preferences.textScaleFactor * 100).round()}% scale',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                          _preferences.textScaleFactor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          _buildSettingCard(
            icon: Icons.animation,
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and transitions',
            child: Switch(
              value: _preferences.reduceMotion,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(_preferences.copyWith(reduceMotion: value));
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Input Accessibility Section
          _buildSectionHeader('Input & Navigation'),
          _buildSettingCard(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Feel vibrations for button presses and actions',
            child: Switch(
              value: _preferences.hapticFeedback,
              onChanged: (value) {
                if (value) HapticFeedback.lightImpact(); // Demo the feedback
                _updatePreferences(
                    _preferences.copyWith(hapticFeedback: value));
              },
            ),
          ),

          _buildSettingCard(
            icon: Icons.keyboard,
            title: 'Keyboard Navigation',
            subtitle: 'Enable keyboard shortcuts and focus indicators',
            child: Switch(
              value: _preferences.keyboardNavigation,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(
                    _preferences.copyWith(keyboardNavigation: value));
              },
            ),
          ),

          _buildSettingCard(
            icon: Icons.volume_up,
            title: 'Sound Feedback',
            subtitle: 'Play sounds for important actions',
            child: Switch(
              value: _preferences.soundFeedback,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(_preferences.copyWith(soundFeedback: value));
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Screen Reader Section
          _buildSectionHeader('Screen Reader'),
          _buildSettingCard(
            icon: Icons.accessibility,
            title: 'Screen Reader Optimizations',
            subtitle: 'Enhanced descriptions and navigation for screen readers',
            child: Switch(
              value: _preferences.screenReaderOptimizations,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(
                    _preferences.copyWith(screenReaderOptimizations: value));
              },
            ),
          ),

          _buildSettingCard(
            icon: Icons.description,
            title: 'Verbose Descriptions',
            subtitle: 'Provide detailed descriptions of interface elements',
            child: Switch(
              value: _preferences.verboseDescriptions,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                _updatePreferences(
                    _preferences.copyWith(verboseDescriptions: value));
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // System Information Section
          _buildSectionHeader('System Information'),
          _buildInfoCard(
            icon: Icons.info,
            title: 'Screen Reader Status',
            subtitle: _accessibilityService.isScreenReaderEnabled
                ? 'Screen reader is active'
                : 'No screen reader detected',
            status: _accessibilityService.isScreenReaderEnabled,
          ),

          _buildInfoCard(
            icon: Icons.contrast,
            title: 'System High Contrast',
            subtitle: _accessibilityService.isHighContrastEnabled
                ? 'System high contrast is enabled'
                : 'System high contrast is disabled',
            status: _accessibilityService.isHighContrastEnabled,
          ),

          _buildInfoCard(
            icon: Icons.animation,
            title: 'System Reduced Motion',
            subtitle: _accessibilityService.isReducedMotionEnabled
                ? 'System reduced motion is enabled'
                : 'System reduced motion is disabled',
            status: _accessibilityService.isReducedMotionEnabled,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Color Contrast Testing
          _buildSectionHeader('Color Contrast Testing'),
          _buildColorContrastReport(),

          const SizedBox(height: AppSpacing.xl),

          // Help Section
          _buildSectionHeader('Help & Resources'),
          _buildHelpCard(
            icon: Icons.help,
            title: 'Accessibility Features Guide',
            subtitle: 'Learn about all accessibility features in this app',
            onTap: () => _showAccessibilityGuide(context),
          ),

          _buildHelpCard(
            icon: Icons.keyboard_alt,
            title: 'Keyboard Shortcuts',
            subtitle: 'View all available keyboard shortcuts',
            onTap: () => _showKeyboardShortcuts(context),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool status,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: status ? AppColors.success : AppColors.disabled,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              status ? Icons.check_circle : Icons.cancel,
              color: status ? AppColors.success : AppColors.disabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorContrastReport() {
    final reports = AccessibilityColors.validateAppColors();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WCAG Compliance Report',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...reports.entries.map((entry) {
              final report = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      report.meetsAA ? Icons.check_circle : Icons.warning,
                      color: report.meetsAA
                          ? AppColors.success
                          : AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    Text(
                      report.toString(),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAccessibilityGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Features'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This app includes comprehensive accessibility features:'),
              SizedBox(height: AppSpacing.md),
              Text('• Screen reader support with detailed descriptions'),
              Text('• Keyboard navigation for all interactive elements'),
              Text('• High contrast mode for better visibility'),
              Text('• Adjustable text size and scaling'),
              Text('• Reduced motion options'),
              Text('• Haptic feedback for tactile response'),
              Text('• Voice input with accessibility alternatives'),
              Text('• WCAG 2.1 AA compliant color contrasts'),
              SizedBox(height: AppSpacing.md),
              Text(
                  'All features work with system accessibility settings and can be customized in this screen.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Global shortcuts:', style: AppTextStyles.titleSmall),
              SizedBox(height: AppSpacing.sm),
              Text('• Ctrl+S or Ctrl+Enter: Save task'),
              Text('• Escape: Cancel or close'),
              Text('• Tab: Navigate between elements'),
              Text('• Space/Enter: Activate buttons'),
              SizedBox(height: AppSpacing.md),
              Text('Task creation shortcuts:', style: AppTextStyles.titleSmall),
              SizedBox(height: AppSpacing.sm),
              Text('• Ctrl+1: Set due date to today'),
              Text('• Ctrl+2: Set due date to tomorrow'),
              SizedBox(height: AppSpacing.md),
              Text('Navigation shortcuts:', style: AppTextStyles.titleSmall),
              SizedBox(height: AppSpacing.sm),
              Text('• Arrow keys: Navigate calendar'),
              Text('• Enter: Select calendar date'),
              Text('• Ctrl+Home: Go to today'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
