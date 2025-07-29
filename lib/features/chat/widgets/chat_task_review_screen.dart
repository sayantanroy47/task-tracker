import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/chat_integration_provider.dart';
import '../providers/chat_integration_state.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/constants/constants.dart';

/// Screen for reviewing and editing extracted tasks from chat messages
class ChatTaskReviewScreen extends ConsumerStatefulWidget {
  final SharedContent sharedContent;
  
  const ChatTaskReviewScreen({
    required this.sharedContent,
    super.key,
  });

  @override
  ConsumerState<ChatTaskReviewScreen> createState() => _ChatTaskReviewScreenState();
}

class _ChatTaskReviewScreenState extends ConsumerState<ChatTaskReviewScreen> {
  @override
  void initState() {
    super.initState();
    // Process the shared content when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatIntegrationProvider.notifier).processSharedContent(widget.sharedContent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatIntegrationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Tasks'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (chatState is ChatIntegrationTasksExtracted)
            TextButton(
              onPressed: () => _confirmAllTasks(context),
              child: const Text('Create All'),
            ),
        ],
      ),
      body: _buildBody(context, chatState),
    );
  }

  Widget _buildBody(BuildContext context, ChatIntegrationState state) {
    return switch (state) {
      ChatIntegrationProcessing() => _buildProcessingView(context),
      ChatIntegrationTasksExtracted(:final extractedTasks) => 
        _buildTasksReview(context, extractedTasks),
      ChatIntegrationNoTasksFound() => _buildNoTasksView(context),
      ChatIntegrationError(:final message) => _buildErrorView(context, message),
      ChatIntegrationCreatingTasks() => _buildCreatingView(context),
      ChatIntegrationSuccess(:final createdTasks) => 
        _buildSuccessView(context, createdTasks),
      _ => _buildIdleView(context),
    };
  }

  Widget _buildProcessingView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing message for tasks...'),
        ],
      ),
    );
  }

  Widget _buildTasksReview(BuildContext context, List<ExtractedTask> tasks) {
    return Column(
      children: [
        // Original message preview
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Message',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sharedContent.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (widget.sharedContent.appName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'From: ${widget.sharedContent.appName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Extracted tasks list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _ExtractedTaskCard(
                task: tasks[index],
                index: index,
                onEdit: (updatedTask) => _editTask(index, updatedTask),
                onRemove: () => _removeTask(index),
              );
            },
          ),
        ),
        
        // Bottom actions
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: tasks.isNotEmpty ? () => _confirmAllTasks(context) : null,
                  child: Text('Create ${tasks.length} Task${tasks.length == 1 ? '' : 's'}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoTasksView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Tasks Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any tasks in this message.\nTry sharing a message with clear action items.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing Error',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => ref.read(chatIntegrationProvider.notifier)
                    .processSharedContent(widget.sharedContent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatingView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Creating tasks...'),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, List<Task> createdTasks) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Success!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${createdTasks.length} task${createdTasks.length == 1 ? '' : 's'} from your message.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could navigate to tasks screen to show created tasks
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleView(BuildContext context) {
    return const Center(
      child: Text('Ready to process messages...'),
    );
  }

  void _editTask(int index, ExtractedTask updatedTask) {
    ref.read(chatIntegrationProvider.notifier).editExtractedTask(index, updatedTask);
  }

  void _removeTask(int index) {
    ref.read(chatIntegrationProvider.notifier).removeExtractedTask(index);
  }

  void _confirmAllTasks(BuildContext context) {
    final state = ref.read(chatIntegrationProvider);
    if (state is ChatIntegrationTasksExtracted) {
      ref.read(chatIntegrationProvider.notifier).confirmAndCreateTasks(state.extractedTasks);
    }
  }
}

/// Card widget for displaying an extracted task with editing capabilities
class _ExtractedTaskCard extends ConsumerWidget {
  final ExtractedTask task;
  final int index;
  final Function(ExtractedTask) onEdit;
  final VoidCallback onRemove;

  const _ExtractedTaskCard({
    required this.task,
    required this.index,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with confidence and actions
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _ConfidenceBadge(confidence: task.confidence),
                      const SizedBox(width: 8),
                      if (task.suggestedCategory != null)
                        CategoryChip(
                          categoryName: task.suggestedCategory!,
                          isSelected: true,
                          onTap: () => _showCategoryPicker(context),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditDialog(context);
                        break;
                      case 'remove':
                        onRemove();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Task title
            Text(
              task.extractedTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Description if available
            if (task.extractedDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                task.extractedDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            // Date and time if available
            if (task.extractedDate != null || task.extractedTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(task.extractedDate, task.extractedTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
            
            // Priority indicator
            if (task.inferredPriority != TaskPriority.medium) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(context, task.inferredPriority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.inferredPriority.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getPriorityColor(context, task.inferredPriority),
                    ),
                  ),
                ],
              ),
            ],
            
            // Keywords if available
            if (task.keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: task.keywords.map((keyword) => Chip(
                  label: Text(keyword),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    final now = DateTime.now();
    String dateStr = 'No date';
    
    if (date != null) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      if (dateOnly == today) {
        dateStr = 'Today';
      } else if (dateOnly == tomorrow) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = '${date.month}/${date.day}/${date.year}';
      }
    }
    
    if (time != null) {
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      dateStr += ' at $displayHour:$minuteStr $period';
    }
    
    return dateStr;
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Theme.of(context).colorScheme.error;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Theme.of(context).colorScheme.primary;
      case TaskPriority.low:
        return Theme.of(context).colorScheme.outline;
    }
  }

  void _showCategoryPicker(BuildContext context) {
    // TODO: Implement category picker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category picker coming soon')),
    );
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implement task editing dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task editing coming soon')),
    );
  }
}

/// Widget showing confidence level as a colored badge
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (confidence * 100).round();
    final color = _getConfidenceColor(context, confidence);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$confidencePercent%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getConfidenceColor(BuildContext context, double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }
}