import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/services/accessibility_service.dart';

/// Voice input button with animation states
/// Optimized for accessibility and clear visual feedback
class VoiceInputButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isListening;
  final bool isProcessing;
  final bool isEnabled;
  final double size;
  final String? tooltip;

  const VoiceInputButton({
    super.key,
    this.onPressed,
    this.isListening = false,
    this.isProcessing = false,
    this.isEnabled = true,
    this.size = 64.0,
    this.tooltip,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  
  // Accessibility support
  late AccessibilityService _accessibilityService;
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize accessibility service
    _accessibilityService = AccessibilityService();
    
    // Pulse animation for listening state (respect reduced motion)
    _pulseController = AnimationController(
      duration: _accessibilityService.isReducedMotionEnabled 
          ? const Duration(milliseconds: 500)
          : AppDurations.voicePulse,
      vsync: this,
    );
    
    // Ripple animation for processing state
    _rippleController = AnimationController(
      duration: _accessibilityService.isReducedMotionEnabled
          ? const Duration(milliseconds: 200)
          : AppDurations.medium,
      vsync: this,
    );
    
    // Focus handling for keyboard navigation
    _focusNode.addListener(_onFocusChanged);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isKeyboardFocused = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation state changes (respect reduced motion)
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        if (!_accessibilityService.isReducedMotionEnabled) {
          _pulseController.repeat(reverse: true);
        }
        _accessibilityService.announce(_getAccessibilityLabel());
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
    
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        if (!_accessibilityService.isReducedMotionEnabled) {
          _rippleController.repeat();
        }
        _accessibilityService.announce('Processing voice input');
      } else {
        _rippleController.stop();
        _rippleController.reset();
      }
    }
  }

  Color _getButtonColor() {
    if (!widget.isEnabled) {
      return AppColors.disabled;
    } else if (widget.isListening) {
      return AppColors.voiceActive;
    } else if (widget.isProcessing) {
      return AppColors.voiceProcessing;
    } else {
      return AppColors.primary;
    }
  }

  IconData _getButtonIcon() {
    if (widget.isProcessing) {
      return Icons.hourglass_top;
    } else if (widget.isListening) {
      return Icons.mic;
    } else {
      return Icons.mic_none;
    }
  }

  String _getAccessibilityLabel() {
    if (widget.isProcessing) {
      return 'Processing voice input';
    } else if (widget.isListening) {
      return 'Listening... Tap to stop';
    } else {
      return widget.tooltip ?? 'Voice input button';
    }
  }

  String _createDetailedHint() {
    if (widget.isProcessing) {
      return 'Voice input is being processed. Please wait.';
    } else if (widget.isListening) {
      return 'Microphone is active. Speak your task now. Tap to stop recording.';
    } else {
      return 'Double tap to start voice input. Speak your task and the app will create it for you.';
    }
  }

  void _handleActivation() {
    if (!widget.isEnabled) return;
    
    // Provide haptic feedback
    _accessibilityService.provideFeedback(
      type: widget.isListening 
          ? HapticFeedbackType.mediumImpact 
          : HapticFeedbackType.lightImpact,
    );
    
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor();
    final icon = _getButtonIcon();
    final accessibilityLabel = _getAccessibilityLabel();
    final isHighContrast = _accessibilityService.isHighContrastEnabled;
    final minSize = _accessibilityService.minTouchTargetSize;
    final actualSize = widget.size < minSize ? minSize : widget.size;
    
    return _accessibilityService.createFocusWrapper(
      focusNode: _focusNode,
      focusColor: Theme.of(context).colorScheme.primary,
      borderWidth: 3.0,
      borderRadius: BorderRadius.circular(actualSize / 2),
      child: Semantics(
        button: true,
        enabled: widget.isEnabled,
        label: accessibilityLabel,
        hint: _createDetailedHint(),
        liveRegion: widget.isListening || widget.isProcessing,
        child: InkWell(
          onTap: widget.isEnabled ? _handleActivation : null,
          focusNode: _focusNode,
          borderRadius: BorderRadius.circular(actualSize / 2),
          child: Container(
            width: actualSize,
            height: actualSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: _isKeyboardFocused 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3.0,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
            // Ripple effect for processing state
            if (widget.isProcessing)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: widget.size * (1 + _rippleAnimation.value * 0.5),
                    height: widget.size * (1 + _rippleAnimation.value * 0.5),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            
            // Main button with pulse animation
            AnimatedBuilder(
              animation: widget.isListening ? _pulseAnimation : kAlwaysCompleteAnimation,
              builder: (context, child) {
                final scale = widget.isListening ? _pulseAnimation.value : 1.0;
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: widget.isListening ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: widget.isProcessing
                        ? _buildProcessingIcon()
                        : Icon(
                            icon,
                            size: widget.size * 0.4,
                            color: Colors.white,
                          ),
                  ),
                );
              },
            ),
            
            // Voice level indicator (visual feedback during listening)
            if (widget.isListening)
              Positioned(
                bottom: 0,
                child: _buildVoiceLevelIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIcon() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rippleController.value * 2 * pi,
          child: Icon(
            Icons.sync,
            size: widget.size * 0.4,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildVoiceLevelIndicator() {
    return Container(
      width: widget.size * 0.9,
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Create wave effect with different frequencies for each bar
              final frequency = 1.0 + (index * 0.3);
              final phase = (_pulseController.value * 2 * 3.14159 * frequency) + (index * 0.5);
              final amplitude = (0.3 + 0.7 * (sin(phase).abs())) * 
                               (1.0 - (index * 0.1)); // Diminishing effect
              
              return Container(
                width: 2,
                height: 6 * amplitude.clamp(0.2, 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: Colors.white.withOpacity(0.9),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Compact voice input button for use in app bars or toolbars
class CompactVoiceButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isListening;
  final bool isProcessing;
  final bool isEnabled;

  const CompactVoiceButton({
    super.key,
    this.onPressed,
    this.isListening = false,
    this.isProcessing = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return VoiceInputButton(
      onPressed: onPressed,
      isListening: isListening,
      isProcessing: isProcessing,
      isEnabled: isEnabled,
      size: 40.0,
      tooltip: 'Voice input',
    );
  }
}

/// Large voice input button for main action
class LargeVoiceButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isListening;
  final bool isProcessing;
  final bool isEnabled;
  final String? label;

  const LargeVoiceButton({
    super.key,
    this.onPressed,
    this.isListening = false,
    this.isProcessing = false,
    this.isEnabled = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceInputButton(
          onPressed: onPressed,
          isListening: isListening,
          isProcessing: isProcessing,
          isEnabled: isEnabled,
          size: 80.0,
          tooltip: label ?? 'Add task with voice',
        ),
        
        if (label != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: isEnabled 
                  ? Theme.of(context).colorScheme.onSurface
                  : AppColors.disabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}