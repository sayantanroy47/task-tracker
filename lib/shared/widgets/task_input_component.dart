import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';
import 'category_chip.dart';

/// Task input component for creating and editing tasks
/// Supports voice input integration and smart suggestions
class TaskInputComponent extends StatefulWidget {
  final Task? initialTask;
  final List<Category> categories;
  final ValueChanged<Task>? onTaskCreated;
  final ValueChanged<Task>? onTaskUpdated;
  final VoidCallback? onCancel;
  final String? initialText;
  final Category? suggestedCategory;
  final DateTime? suggestedDueDate;
  final DateTime? suggestedDueTime;
  final bool isVoiceInput;
  final bool showAdvancedOptions;

  const TaskInputComponent({
    super.key,
    this.initialTask,
    required this.categories,
    this.onTaskCreated,
    this.onTaskUpdated,
    this.onCancel,
    this.initialText,
    this.suggestedCategory,
    this.suggestedDueDate,
    this.suggestedDueTime,
    this.isVoiceInput = false,
    this.showAdvancedOptions = true,
  });

  @override
  State<TaskInputComponent> createState() => _TaskInputComponentState();
}

class _TaskInputComponentState extends State<TaskInputComponent> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  Category? _selectedCategory;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _hasReminder = false;
  List<ReminderInterval> _reminderIntervals = [];
  
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(
      text: widget.initialText ?? widget.initialTask?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTask?.description ?? '',
    );
    
    // Initialize with existing task data or suggestions
    if (widget.initialTask != null) {
      _initializeFromTask(widget.initialTask!);
    } else {
      _initializeFromSuggestions();
    }
    
    _showAdvancedOptions = widget.showAdvancedOptions;
    
    // Auto-focus title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isVoiceInput) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  void _initializeFromTask(Task task) {
    _selectedCategory = widget.categories.cast<Category?>()
        .firstWhere((cat) => cat?.id == task.categoryId, orElse: () => null);
    _selectedDueDate = task.dueDate;
    _selectedDueTime = task.dueTime != null 
        ? TimeOfDay.fromDateTime(task.dueTime!) 
        : null;
    _selectedPriority = task.priority;
    _hasReminder = task.hasReminder;
    _reminderIntervals = List.from(task.reminderIntervals);
  }

  void _initializeFromSuggestions() {
    _selectedCategory = widget.suggestedCategory ?? 
        (widget.categories.isNotEmpty ? widget.categories.first : null);
    _selectedDueDate = widget.suggestedDueDate;
    _selectedDueTime = widget.suggestedDueTime != null 
        ? TimeOfDay.fromDateTime(widget.suggestedDueTime!) 
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dueDateTime = _selectedDueDate != null && _selectedDueTime != null
        ? DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
            _selectedDueTime!.hour,
            _selectedDueTime!.minute,
          )
        : null;

    if (widget.initialTask != null) {
      // Update existing task
      final updatedTask = widget.initialTask!.copyWith(
        title: title,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id ?? widget.categories.first.id,
        dueDate: _selectedDueDate,
        dueTime: dueDateTime,
        priority: _selectedPriority,
        hasReminder: _hasReminder,
        reminderIntervals: _reminderIntervals,
      );
      widget.onTaskUpdated?.call(updatedTask);
    } else {
      // Create new task
      final newTask = Task.create(
        title: title,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id ?? widget.categories.first.id,
        dueDate: _selectedDueDate,
        dueTime: dueDateTime,
        priority: _selectedPriority,
        source: widget.isVoiceInput ? TaskSource.voice : TaskSource.manual,
        hasReminder: _hasReminder,
        reminderIntervals: _reminderIntervals,
      );
      widget.onTaskCreated?.call(newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialTask != null;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with drag indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isEditing ? 'Edit Task' : 'New Task',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
            
            // Title input
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'What do you need to do?',
                prefixIcon: Icon(Icons.task_alt),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
              maxLength: 100,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return isFocused && maxLength != null
                    ? Text(
                        '$currentLength/$maxLength',
                        style: AppTextStyles.caption,
                      )
                    : null;
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Description input (optional)
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details...',
                prefixIcon: Icon(Icons.notes),
              ),
              textInputAction: TextInputAction.done,
              maxLines: 2,
              maxLength: 200,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return isFocused && maxLength != null
                    ? Text(
                        '$currentLength/$maxLength',
                        style: AppTextStyles.caption,
                      )
                    : null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Category selection
            Text(
              'Category',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            CategoryChipWrap(
              categories: widget.categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Quick date/time options
            _buildQuickDateTimeOptions(),
            
            // Advanced options toggle
            if (widget.showAdvancedOptions) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                icon: Icon(_showAdvancedOptions 
                    ? Icons.keyboard_arrow_up 
                    : Icons.keyboard_arrow_down),
                label: Text(_showAdvancedOptions 
                    ? 'Hide Advanced Options' 
                    : 'Show Advanced Options'),
              ),
            ],
            
            // Advanced options
            if (_showAdvancedOptions) ...[
              const SizedBox(height: AppSpacing.md),
              _buildAdvancedOptions(),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(isEditing ? 'Update Task' : 'Create Task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateTimeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date & Time',
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Quick date options
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _buildQuickDateChip('Today', DateTime.now()),
            _buildQuickDateChip('Tomorrow', DateTime.now().add(const Duration(days: 1))),
            _buildQuickDateChip('This Weekend', _getNextWeekend()),
            _buildQuickDateChip('Custom', null, isCustom: true),
          ],
        ),
        
        // Selected date/time display
        if (_selectedDueDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _formatSelectedDateTime(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.access_time),
                  color: AppColors.primary,
                  tooltip: 'Set time',
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedDueDate = null;
                    _selectedDueTime = null;
                  }),
                  icon: const Icon(Icons.clear),
                  color: AppColors.primary,
                  tooltip: 'Clear date',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickDateChip(String label, DateTime? date, {bool isCustom = false}) {
    final isSelected = isCustom 
        ? _selectedDueDate != null && !_isQuickDate(_selectedDueDate!)
        : _selectedDueDate != null && _isSameDay(_selectedDueDate!, date);
    
    return ActionChip(
      label: Text(label),
      onPressed: () {
        if (isCustom) {
          _selectCustomDate();
        } else {
          setState(() {
            _selectedDueDate = date;
            _selectedDueTime = null; // Reset time when changing date
          });
        }
      },
      backgroundColor: isSelected 
          ? AppColors.primary 
          : null,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority selection
        Text(
          'Priority',
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: TaskPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return ActionChip(
              label: Text(priority.displayName),
              onPressed: () => setState(() => _selectedPriority = priority),
              backgroundColor: isSelected ? _getPriorityColor(priority) : null,
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Reminder options
        Row(
          children: [
            Text(
              'Reminders',
              style: AppTextStyles.titleSmall,
            ),
            const Spacer(),
            Switch(
              value: _hasReminder,
              onChanged: (value) => setState(() => _hasReminder = value),
            ),
          ],
        ),
        
        if (_hasReminder) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: ReminderInterval.values.map((interval) {
              final isSelected = _reminderIntervals.contains(interval);
              return FilterChip(
                label: Text(interval.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _reminderIntervals.add(interval);
                    } else {
                      _reminderIntervals.remove(interval);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _selectCustomDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedDueDate = selectedDate;
        _selectedDueTime = null; // Reset time when changing date
      });
    }
  }

  void _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );
    
    if (selectedTime != null) {
      setState(() {
        _selectedDueTime = selectedTime;
      });
    }
  }

  String _formatSelectedDateTime() {
    if (_selectedDueDate == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(_selectedDueDate!.year, _selectedDueDate!.month, _selectedDueDate!.day);
    
    String dateStr;
    if (selectedDay == today) {
      dateStr = 'Today';
    } else if (selectedDay == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('MMM d, y').format(_selectedDueDate!);
    }
    
    if (_selectedDueTime != null) {
      dateStr += ' at ${_selectedDueTime!.format(context)}';
    }
    
    return dateStr;
  }

  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  bool _isQuickDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekend = _getNextWeekend();
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    return selectedDay == today || 
           selectedDay == tomorrow || 
           selectedDay == DateTime(weekend.year, weekend.month, weekend.day);
  }

  bool _isSameDay(DateTime date1, DateTime? date2) {
    if (date2 == null) return false;
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.info;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.urgent:
        return AppColors.error;
    }
  }
}