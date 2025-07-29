import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Comprehensive accessibility service providing WCAG 2.1 AA compliance
/// Handles screen reader support, keyboard navigation, and accessibility preferences
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  /// Current accessibility preferences
  AccessibilityPreferences _preferences = AccessibilityPreferences();
  
  /// Callbacks for accessibility state changes
  final List<VoidCallback> _listeners = [];

  /// Initialize accessibility service
  Future<void> initialize() async {
    await _loadPreferences();
    _setupSystemCallbacks();
  }

  /// Get current accessibility preferences
  AccessibilityPreferences get preferences => _preferences;

  /// Add listener for accessibility changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Update accessibility preferences
  Future<void> updatePreferences(AccessibilityPreferences newPreferences) async {
    _preferences = newPreferences;
    await _savePreferences();
    _notifyListeners();
  }

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.highContrast ||
           _preferences.forceHighContrast;
  }

  /// Check if reduced motion is enabled
  bool get isReducedMotionEnabled {
    return SemanticsBinding.instance.accessibilityFeatures.disableAnimations ||
           _preferences.reduceMotion;
  }

  /// Check if large text is enabled
  bool get isLargeTextEnabled {
    return _preferences.largeText ||
           MediaQueryData.fromWindow(WidgetsBinding.instance.window).textScaleFactor > 1.3;
  }

  /// Get accessible text scale factor
  double get textScaleFactor {
    if (_preferences.largeText) {
      return (_preferences.textScaleFactor > 1.0) ? _preferences.textScaleFactor : 1.5;
    }
    return MediaQueryData.fromWindow(WidgetsBinding.instance.window).textScaleFactor;
  }

  /// Get minimum touch target size
  double get minTouchTargetSize {
    return isLargeTextEnabled ? 48.0 : 44.0;
  }

  /// Provide haptic feedback for interactions
  Future<void> provideFeedback({
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
    bool respectSettings = true,
  }) async {
    if (respectSettings && !_preferences.hapticFeedback) return;
    
    switch (type) {
      case HapticFeedbackType.lightImpact:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        await HapticFeedback.vibrate();
        break;
    }
  }

  /// Announce to screen reader
  void announce(String message, {TextDirection? textDirection}) {
    SemanticsService.announce(
      message,
      textDirection ?? TextDirection.ltr,
    );
  }

  /// Create accessible widget wrapper
  Widget makeAccessible({
    required Widget child,
    required String semanticLabel,
    String? semanticHint,
    String? semanticValue,
    bool? isButton,
    bool? isToggled,
    bool? isSelected,
    bool? isFocusable,
    bool? isLiveRegion,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      value: semanticValue,
      button: isButton ?? false,
      toggled: isToggled,
      selected: isSelected,
      focusable: isFocusable ?? true,
      liveRegion: isLiveRegion ?? false,
      onTap: onTap,
      onLongPress: onLongPress,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }

  /// Create focus wrapper with visual focus indicator
  Widget createFocusWrapper({
    required Widget child,
    required FocusNode focusNode,
    Color? focusColor,
    double borderWidth = 2.0,
    BorderRadius? borderRadius,
    bool showFocusOnKeyboard = true,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final hasFocus = focusNode.hasFocus;
          final showFocus = showFocusOnKeyboard ? hasFocus : false;
          
          return Container(
            decoration: showFocus ? BoxDecoration(
              border: Border.all(
                color: focusColor ?? Theme.of(context).colorScheme.primary,
                width: borderWidth,
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(4.0),
            ) : null,
            child: child,
          );
        },
      ),
    );
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    // In a real app, this would load from SharedPreferences or similar
    // For now, use defaults
    _preferences = AccessibilityPreferences();
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    // In a real app, this would save to SharedPreferences or similar
  }

  /// Setup system accessibility callbacks
  void _setupSystemCallbacks() {
    // Listen for system accessibility changes
    WidgetsBinding.instance.platformDispatcher.onAccessibilityFeaturesChanged = () {
      _notifyListeners();
    };
  }

  /// Notify all listeners of changes
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

/// Accessibility preferences model
class AccessibilityPreferences {
  final bool forceHighContrast;
  final bool reduceMotion;
  final bool largeText;
  final double textScaleFactor;
  final bool hapticFeedback;
  final bool keyboardNavigation;
  final bool screenReaderOptimizations;
  final bool verboseDescriptions;
  final bool soundFeedback;

  const AccessibilityPreferences({
    this.forceHighContrast = false,
    this.reduceMotion = false,
    this.largeText = false,
    this.textScaleFactor = 1.0,
    this.hapticFeedback = true,
    this.keyboardNavigation = true,
    this.screenReaderOptimizations = true,
    this.verboseDescriptions = false,
    this.soundFeedback = false,
  });

  AccessibilityPreferences copyWith({
    bool? forceHighContrast,
    bool? reduceMotion,
    bool? largeText,
    double? textScaleFactor,
    bool? hapticFeedback,
    bool? keyboardNavigation,
    bool? screenReaderOptimizations,
    bool? verboseDescriptions,
    bool? soundFeedback,
  }) {
    return AccessibilityPreferences(
      forceHighContrast: forceHighContrast ?? this.forceHighContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      largeText: largeText ?? this.largeText,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      keyboardNavigation: keyboardNavigation ?? this.keyboardNavigation,
      screenReaderOptimizations: screenReaderOptimizations ?? this.screenReaderOptimizations,
      verboseDescriptions: verboseDescriptions ?? this.verboseDescriptions,
      soundFeedback: soundFeedback ?? this.soundFeedback,
    );
  }
}

/// Haptic feedback types
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

/// Accessibility context extension
extension AccessibilityContext on BuildContext {
  /// Get accessibility service instance
  AccessibilityService get accessibility => AccessibilityService();
  
  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled => AccessibilityService().isScreenReaderEnabled;
  
  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => AccessibilityService().isHighContrastEnabled;
  
  /// Check if reduced motion is enabled
  bool get isReducedMotionEnabled => AccessibilityService().isReducedMotionEnabled;
  
  /// Get text scale factor
  double get accessibilityTextScale => AccessibilityService().textScaleFactor;
  
  /// Get minimum touch target size
  double get minTouchTarget => AccessibilityService().minTouchTargetSize;
  
  /// Provide haptic feedback
  Future<void> hapticFeedback([HapticFeedbackType type = HapticFeedbackType.lightImpact]) {
    return AccessibilityService().provideFeedback(type: type);
  }
  
  /// Announce to screen reader
  void announce(String message) {
    AccessibilityService().announce(message);
  }
}

/// Widget to handle keyboard shortcuts
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback>? shortcuts;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    if (shortcuts == null || shortcuts!.isEmpty) {
      return child;
    }

    return Shortcuts(
      shortcuts: shortcuts!,
      child: Actions(
        actions: {
          for (final entry in shortcuts!.entries)
            _ShortcutAction: CallbackAction<_ShortcutAction>(
              onInvoke: (_) => entry.value(),
            ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _ShortcutAction extends Intent {}

/// Live region for dynamic content announcements
class LiveRegion extends StatefulWidget {
  final Widget child;
  final String? announcement;
  final bool polite;

  const LiveRegion({
    super.key,
    required this.child,
    this.announcement,
    this.polite = true,
  });

  @override
  State<LiveRegion> createState() => _LiveRegionState();
}

class _LiveRegionState extends State<LiveRegion> {
  String? _lastAnnouncement;

  @override
  void didUpdateWidget(LiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.announcement != null && 
        widget.announcement != _lastAnnouncement) {
      _lastAnnouncement = widget.announcement;
      
      // Delay announcement to avoid conflicts
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          AccessibilityService().announce(widget.announcement!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: widget.child,
    );
  }
}