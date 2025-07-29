import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../features/voice/voice.dart';
import 'voice_input_button.dart';

/// Full-screen voice input overlay with visual feedback
/// Provides an immersive voice recording experience
class VoiceInputOverlay extends ConsumerWidget {
  const VoiceInputOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputProvider);
    
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voice Input',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(voiceInputProvider.notifier).cancelVoiceInput();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Voice visualization and status
              _buildVoiceVisualization(context, voiceState),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Status text
              _buildStatusText(voiceState),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Voice input button
              _buildVoiceButton(context, ref, voiceState),
              
              const Spacer(),
              
              // Instructions or partial results
              _buildBottomContent(voiceState),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVoiceVisualization(BuildContext context, VoiceInputState state) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: _buildVisualizationContent(state),
      ),
    );
  }
  
  Widget _buildVisualizationContent(VoiceInputState state) {
    return switch (state) {
      VoiceInputIdle() => const Icon(
          Icons.mic_none,
          size: 80,
          color: Colors.white54,
        ),
      VoiceInputInitializing() => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      VoiceInputListening() => _buildListeningAnimation(),
      VoiceInputProcessing(partialText: _) => _buildProcessingAnimation(),
      VoiceInputConfirmation(parsedInput: _) => const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
      VoiceInputCreating() => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
        ),
      VoiceInputSuccess() => const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
      VoiceInputError(message: _) => const Icon(
          Icons.error,
          size: 80,
          color: Colors.red,
        ),
    };
  }
  
  Widget _buildListeningAnimation() {
    return const VoiceWaveAnimation();
  }
  
  Widget _buildProcessingAnimation() {
    return const VoiceProcessingAnimation();
  }
  
  Widget _buildStatusText(VoiceInputState state) {
    final (text, color) = switch (state) {
      VoiceInputIdle() => ('Tap the microphone to start', Colors.white70),
      VoiceInputInitializing() => ('Initializing voice input...', Colors.white),
      VoiceInputListening() => ('Listening... Speak now', Colors.white),
      VoiceInputProcessing(partialText: _) => ('Processing speech...', Colors.white),
      VoiceInputConfirmation(parsedInput: _) => ('Review your task', Colors.white),
      VoiceInputCreating() => ('Creating task...', Colors.blue),
      VoiceInputSuccess() => ('Task created successfully!', Colors.green),
      VoiceInputError(message: final message) => (message, Colors.red),
    };
    
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildVoiceButton(BuildContext context, WidgetRef ref, VoiceInputState state) {
    final isListening = state is VoiceInputListening;
    final isProcessing = state is VoiceInputProcessing || state is VoiceInputCreating;
    final isEnabled = state is VoiceInputIdle || state is VoiceInputListening;
    
    return LargeVoiceButton(
      onPressed: isEnabled ? () {
        final controller = ref.read(voiceInputProvider.notifier);
        if (isListening) {
          controller.stopVoiceInput();
        } else {
          controller.startVoiceInput();
        }
      } : null,
      isListening: isListening,
      isProcessing: isProcessing,
      isEnabled: isEnabled,
      label: isListening ? 'Tap to stop' : 'Tap to speak',
    );
  }
  
  Widget _buildBottomContent(VoiceInputState state) {
    return switch (state) {
      VoiceInputIdle() => const Text(
          'Speak naturally about your task.\nFor example: "Remind me to call mom tomorrow at 3pm"',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      VoiceInputProcessing(partialText: final text) when text.isNotEmpty => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            '"$text"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      VoiceInputConfirmation(parsedInput: final parsed) => _buildConfirmationContent(parsed),
      VoiceInputError(_) => Consumer(
          builder: (context, ref, child) {
            return TextButton(
              onPressed: () {
                ref.read(voiceInputProvider.notifier).retry();
              },
              child: const Text(
                'Tap to try again',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      _ => const SizedBox.shrink(),
    };
  }
  
  Widget _buildConfirmationContent(ParsedVoiceInput parsed) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Preview:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            parsed.taskTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          
          if (parsed.parsedDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Due: ${_formatDate(parsed.parsedDate!)}${parsed.parsedTime != null ? ' at ${_formatTime(parsed.parsedTime!)}' : ''}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
          
          if (parsed.suggestedCategory != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Category: ${parsed.suggestedCategory}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Edit functionality would be implemented here
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () {
                        ref.read(voiceInputProvider.notifier).confirmAndCreateTask(parsed);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create Task'),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Animated wave visualization for voice input
class VoiceWaveAnimation extends StatefulWidget {
  const VoiceWaveAnimation({super.key});

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create multiple wave animations with different delays
    _animations = List.generate(5, (index) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1,
            0.5 + index * 0.1,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _animations.asMap().entries.map((entry) {
            return Container(
              width: 4,
              height: 60 * entry.value.value,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Processing animation for voice input
class VoiceProcessingAnimation extends StatefulWidget {
  const VoiceProcessingAnimation({super.key});

  @override
  State<VoiceProcessingAnimation> createState() => _VoiceProcessingAnimationState();
}

class _VoiceProcessingAnimationState extends State<VoiceProcessingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3 + 0.7 * _animation.value),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.psychology,
            size: 40,
            color: Colors.white,
          ),
        );
      },
    );
  }
}