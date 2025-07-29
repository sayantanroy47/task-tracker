import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import 'voice_providers.dart';
import 'voice_state.dart';

/// Voice input screen for creating tasks via speech
class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceControllerProvider);
    final voiceController = ref.read(voiceControllerProvider.notifier);

    // Start/stop pulse animation based on listening state
    ref.listen<VoiceState>(voiceControllerProvider, (previous, next) {
      if (next is VoiceStateListening) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Input'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (voiceState is VoiceStateProcessing || voiceState is VoiceStateListening)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => voiceController.stopListening(),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Status text
              Text(
                _getStatusText(voiceState),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle text
              Text(
                _getSubtitleText(voiceState),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Voice visualization area
              _buildVoiceVisualization(context, voiceState),
              
              const Spacer(),
              
              // Transcript display
              if (voiceState is VoiceStateListening && voiceState.currentTranscript.isNotEmpty)
                _buildTranscriptCard(context, voiceState.currentTranscript),
              
              if (voiceState is VoiceStateCompleted)
                _buildTaskPreview(context, voiceState),
              
              const SizedBox(height: 32),
              
              // Action buttons
              _buildActionButtons(context, voiceState, voiceController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceVisualization(BuildContext context, VoiceState state) {
    return SizedBox(
      height: 200,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 120 * (state is VoiceStateListening ? _pulseAnimation.value : 1.0),
              height: 120 * (state is VoiceStateListening ? _pulseAnimation.value : 1.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getVisualizationColor(context, state),
                boxShadow: state is VoiceStateListening
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20 * _pulseAnimation.value,
                          spreadRadius: 10 * _pulseAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getVisualizationIcon(state),
                size: 48,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(BuildContext context, String transcript) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What I heard:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              transcript,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPreview(BuildContext context, VoiceStateCompleted state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Task Created',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.parsedTask.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.parsedTask.description != null) ...[
              const SizedBox(height: 8),
              Text(
                state.parsedTask.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (state.parsedTask.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(state.parsedTask.dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    VoiceState state,
    dynamic voiceController,
  ) {
    switch (state.runtimeType) {
      case VoiceStateIdle:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => voiceController.startListening(),
                icon: const Icon(Icons.mic),
                label: const Text('Start Speaking'),
              ),
            ),
          ],
        );
        
      case VoiceStateListening:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => voiceController.stopListening(),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
        
      case VoiceStateProcessing:
        return const Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: null,
                icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('Processing...'),
              ),
            ),
          ],
        );
        
      case VoiceStateCompleted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => voiceController.reset(),
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Done'),
              ),
            ),
          ],
        );
        
      case VoiceStateError:
        final errorState = state as VoiceStateError;
        return Column(
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorState.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => voiceController.reset(),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusText(VoiceState state) {
    return switch (state.runtimeType) {
      VoiceStateIdle => 'Ready to Listen',
      VoiceStateListening => 'Listening...',
      VoiceStateProcessing => 'Processing',
      VoiceStateCompleted => 'Task Created!',
      VoiceStateError => 'Error',
      _ => 'Ready to Listen',
    };
  }

  String _getSubtitleText(VoiceState state) {
    return switch (state.runtimeType) {
      VoiceStateIdle => 'Tap the microphone to start recording your task',
      VoiceStateListening => 'Speak clearly and describe your task',
      VoiceStateProcessing => 'Converting your speech to a task...',
      VoiceStateCompleted => 'Your task has been created successfully',
      VoiceStateError => 'Something went wrong. Please try again.',
      _ => 'Tap the microphone to start recording your task',
    };
  }

  Color _getVisualizationColor(BuildContext context, VoiceState state) {
    return switch (state.runtimeType) {
      VoiceStateListening => Theme.of(context).colorScheme.primary,
      VoiceStateProcessing => Theme.of(context).colorScheme.secondary,
      VoiceStateCompleted => Theme.of(context).colorScheme.tertiary,
      VoiceStateError => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.surfaceVariant,
    };
  }

  IconData _getVisualizationIcon(VoiceState state) {
    return switch (state.runtimeType) {
      VoiceStateListening => Icons.mic,
      VoiceStateProcessing => Icons.hourglass_empty,
      VoiceStateCompleted => Icons.check,
      VoiceStateError => Icons.error,
      _ => Icons.mic_none,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}