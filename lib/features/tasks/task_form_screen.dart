import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/task_input_component.dart';
import '../../core/navigation/navigation_service.dart';
import 'providers/task_providers.dart';

/// Screen for creating or editing tasks
class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  
  const TaskFormScreen({
    this.taskId,
    super.key,
  });

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  bool get isEditing => widget.taskId != null;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // If editing, load the task data
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTaskData();
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _loadTaskData() async {
    if (widget.taskId == null) return;
    
    try {
      final task = await ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
      if (task != null && mounted) {
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  void _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }
    
    try {
      final taskRepository = ref.read(taskRepositoryProvider);
      
      if (isEditing) {
        // Update existing task
        final existingTask = await taskRepository.getTaskById(widget.taskId!);
        if (existingTask != null) {
          final updatedTask = existingTask.copyWith(
            title: title,
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
          );
          await taskRepository.updateTask(updatedTask);
        }
      } else {
        // Create new task using the task input component logic
        // This will be handled by the TaskInputComponent
      }
      
      if (mounted) {
        // Refresh task list
        ref.invalidate(tasksProvider);
        
        // Navigate back
        context.pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Task updated successfully' : 'Task created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditing) ...[
              // Use the existing TaskInputComponent for new tasks
              const TaskInputComponent(),
            ] else ...[
              // Simple form for editing
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }
}