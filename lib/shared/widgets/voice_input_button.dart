import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: AppDurations.voicePulse,
      vsync: this,
    );
    
    // Ripple animation for processing state
    _rippleController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );
    
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
    super.dispose();
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation state changes
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
    
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _rippleController.repeat();
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
      return widget.tooltip ?? 'Tap to start voice input';
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor();
    final icon = _getButtonIcon();
    final accessibilityLabel = _getAccessibilityLabel();
    
    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: accessibilityLabel,
      hint: widget.isListening 
          ? 'Speak your task now' 
          : 'Double tap to activate voice input',
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onPressed : null,
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
                    child: Icon(
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

  Widget _buildVoiceLevelIndicator() {
    return Container(
      width: widget.size * 0.8,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withOpacity(0.3),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Simulate voice level with animation
          final level = (_pulseAnimation.value - 1.0) * 5 + 0.3;
          
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: (widget.size * 0.8) * level.clamp(0.0, 1.0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white,
              ),
            ),
          );
        },
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