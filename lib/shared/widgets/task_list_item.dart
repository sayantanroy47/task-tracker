import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';
import 'category_chip.dart';

/// Task list item with swipe gestures and completion animations
/// Optimized for quick task management and accessibility
class TaskListItem extends StatefulWidget {
  final Task task;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final ValueChanged<Task>? onToggleComplete;
  final VoidCallback? onDelete;
  final bool showCategory;
  final bool enableSwipeActions;

  const TaskListItem({
    super.key,
    required this.task,
    this.category,
    this.onTap,
    this.onEdit,
    this.onToggleComplete,
    this.onDelete,
    this.showCategory = true,
    this.enableSwipeActions = true,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with TickerProviderStateMixin {
  late AnimationController _completionController;
  late AnimationController _swipeController;
  late Animation<double> _completionAnimation;
  late Animation<Offset> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Completion animation controller
    _completionController = AnimationController(
      duration: AppDurations.taskCompletion,
      vsync: this,
    );
    
    // Swipe animation controller
    _swipeController = AnimationController(
      duration: AppDurations.swipeAnimation,
      vsync: this,
    );
    
    _completionAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeInOut,
    ));
    
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    
    // Start with completed animation if task is already completed
    if (widget.task.isCompleted) {
      _completionController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _completionController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle completion state changes
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _completionController.forward();
      } else {
        _completionController.reverse();
      }
    }
  }

  void _handleToggleComplete() {
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    if (widget.onToggleComplete != null) {
      final updatedTask = widget.task.isCompleted 
          ? widget.task.uncomplete() 
          : widget.task.complete();
      widget.onToggleComplete!(updatedTask);
    }
  }

  void _handleSwipeComplete() {
    _swipeController.forward().then((_) {
      _handleToggleComplete();
      _swipeController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.task.isOverdue;
    final isDueToday = widget.task.isDueToday;
    
    // Color logic for visual hierarchy
    final backgroundColor = widget.task.isCompleted
        ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
        : isOverdue
            ? AppColors.error.withOpacity(0.1)
            : isDueToday
                ? AppColors.warning.withOpacity(0.1)
                : theme.colorScheme.surface;
    
    final borderColor = widget.task.isCompleted
        ? AppColors.success.withOpacity(0.3)
        : isOverdue
            ? AppColors.error.withOpacity(0.3)
            : isDueToday
                ? AppColors.warning.withOpacity(0.3)
                : Colors.transparent;

    return AnimatedBuilder(
      animation: _completionAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.task.isCompleted ? 0.6 : 1.0,
          child: SlideTransition(
            position: _swipeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: widget.enableSwipeActions
                  ? _buildSwipeWrapper()
                  : _buildTaskContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeWrapper() {
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          if (widget.onEdit != null) {
            widget.onEdit!();
          }
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to complete
          _handleToggleComplete();
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(DismissDirection.startToEnd),
      secondaryBackground: _buildSwipeBackground(DismissDirection.endToStart),
      child: _buildTaskContent(),
    );
  }

  Widget _buildSwipeBackground(DismissDirection direction) {
    final isEdit = direction == DismissDirection.startToEnd;
    final color = isEdit ? AppColors.info : AppColors.success;
    final icon = isEdit ? Icons.edit : Icons.check;
    final label = isEdit ? 'Edit' : 'Complete';
    
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskContent() {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Completion checkbox
            _buildCompletionCheckbox(),
            
            const SizedBox(width: AppSpacing.md),
            
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title
                  Text(
                    widget.task.title,
                    style: widget.task.isCompleted
                        ? AppTextStyles.withStrikethrough(AppTextStyles.taskTitle)
                        : AppTextStyles.taskTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Task description (if present)
                  if (widget.task.description != null &&
                      widget.task.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.task.description!,
                      style: widget.task.isCompleted
                          ? AppTextStyles.withStrikethrough(AppTextStyles.taskDescription)
                          : AppTextStyles.taskDescription.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Task metadata (due date, category)
                  if (widget.task.dueDateTimeDisplay != null ||
                      (widget.showCategory && widget.category != null)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Due date/time
                        if (widget.task.dueDateTimeDisplay != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: widget.task.isOverdue
                                ? AppColors.error
                                : widget.task.isDueToday
                                    ? AppColors.warning
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            widget.task.dueDateTimeDisplay!,
                            style: AppTextStyles.taskDateTime.copyWith(
                              color: widget.task.isOverdue
                                  ? AppColors.error
                                  : widget.task.isDueToday
                                      ? AppColors.warning
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: widget.task.isOverdue || widget.task.isDueToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          
                          if (widget.showCategory && widget.category != null)
                            const SizedBox(width: AppSpacing.md),
                        ],
                        
                        // Category
                        if (widget.showCategory && widget.category != null)
                          CategoryDisplay(
                            category: widget.category!,
                            isCompact: true,
                            textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        
                        const Spacer(),
                        
                        // Task source indicator
                        if (widget.task.source != TaskSource.manual)
                          Icon(
                            _getSourceIcon(widget.task.source),
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCheckbox() {
    return GestureDetector(
      onTap: _handleToggleComplete,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.task.isCompleted 
              ? AppColors.success 
              : Colors.transparent,
          border: Border.all(
            color: widget.task.isCompleted 
                ? AppColors.success 
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: widget.task.isCompleted
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  IconData _getSourceIcon(TaskSource source) {
    switch (source) {
      case TaskSource.voice:
        return Icons.mic;
      case TaskSource.chat:
        return Icons.chat;
      case TaskSource.calendar:
        return Icons.calendar_today;
      case TaskSource.manual:
        return Icons.edit;
    }
  }
}