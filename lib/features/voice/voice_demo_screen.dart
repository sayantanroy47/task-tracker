import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../shared/widgets/widgets.dart';
import 'voice.dart';

/// Demo screen showing voice input functionality
/// This demonstrates the integration of speech recognition with the UI
class VoiceDemoScreen extends ConsumerWidget {
  const VoiceDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputProvider);
    final voiceAvailable = ref.watch(voiceAvailabilityProvider);
    final microphonePermission = ref.watch(microphonePermissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Input Demo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Service Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Voice availability
                    Row(
                      children: [
                        Icon(
                          voiceAvailable.when(
                            data: (available) => available ? Icons.check_circle : Icons.cancel,
                            loading: () => Icons.hourglass_empty,
                            error: (_, __) => Icons.error,
                          ),
                          color: voiceAvailable.when(
                            data: (available) => available ? Colors.green : Colors.red,
                            loading: () => Colors.orange,
                            error: (_, __) => Colors.red,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Voice Recognition: ${voiceAvailable.when(
                          data: (available) => available ? 'Available' : 'Not Available',
                          loading: () => 'Checking...',
                          error: (_, __) => 'Error',
                        )}'),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Microphone permission
                    Row(
                      children: [
                        Icon(
                          microphonePermission.when(
                            data: (granted) => granted ? Icons.check_circle : Icons.cancel,
                            loading: () => Icons.hourglass_empty,
                            error: (_, __) => Icons.error,
                          ),
                          color: microphonePermission.when(
                            data: (granted) => granted ? Colors.green : Colors.red,
                            loading: () => Colors.orange,
                            error: (_, __) => Colors.red,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Microphone Permission: ${microphonePermission.when(
                          data: (granted) => granted ? 'Granted' : 'Denied',
                          loading: () => 'Checking...',
                          error: (_, __) => 'Error',
                        )}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Current State Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Voice State',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStateDisplay(voiceState),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: microphonePermission.when(
                      data: (granted) => !granted ? () {
                        ref.read(appStateProvider.notifier).requestVoicePermissions();
                      } : null,
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                    child: const Text('Request Permission'),
                  ),
                ),
                
                const SizedBox(width: AppSpacing.md),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: voiceAvailable.when(
                      data: (available) => available ? () {
                        _showVoiceInputOverlay(context);
                      } : null,
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                    child: const Text('Start Voice Input'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Quick Voice Button
            Center(
              child: Consumer(
                builder: (context, ref, child) {
                  return LargeVoiceButton(
                    onPressed: () => _showVoiceInputOverlay(context),
                    isListening: voiceState is VoiceInputListening,
                    isProcessing: voiceState is VoiceInputProcessing || voiceState is VoiceInputCreating,
                    isEnabled: voiceAvailable.value == true && microphonePermission.value == true,
                    label: 'Say something...',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStateDisplay(VoiceInputState state) {
    final (text, color, icon) = switch (state) {
      VoiceInputIdle() => ('Idle - Ready to start', Colors.grey, Icons.mic_none),
      VoiceInputInitializing() => ('Initializing voice service...', Colors.blue, Icons.settings_voice),
      VoiceInputListening() => ('Listening - Speak now!', Colors.green, Icons.mic),
      VoiceInputProcessing(partialText: final text) => ('Processing: "$text"', Colors.orange, Icons.psychology),
      VoiceInputConfirmation(parsedInput: final parsed) => ('Confirm task: "${parsed.taskTitle}"', Colors.blue, Icons.check_circle_outline),
      VoiceInputCreating() => ('Creating task...', Colors.blue, Icons.add_task),
      VoiceInputSuccess() => ('Task created successfully!', Colors.green, Icons.check_circle),
      VoiceInputError(message: final message) => ('Error: $message', Colors.red, Icons.error),
    };
    
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
  
  void _showVoiceInputOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VoiceInputOverlay(),
    );
  }
}

/// Usage examples and tips widget
class VoiceUsageExamplesWidget extends StatelessWidget {
  const VoiceUsageExamplesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const examples = [
      'Remind me to call mom tomorrow at 3pm',
      'Buy groceries this weekend',
      'Doctor appointment next Tuesday morning',
      'Pay bills by the end of this month',
      'Work meeting on Friday at 2:30',
      'Exercise tonight',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Input Examples',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try saying phrases like these:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            ...examples.map((example) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.keyboard_voice, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '"$example"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}