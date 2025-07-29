import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/services/accessibility_service.dart';
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
  
  // Accessibility support
  final FocusNode _focusNode = FocusNode();
  late AccessibilityService _accessibilityService;
  bool _isKeyboardActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize accessibility service
    _accessibilityService = AccessibilityService();
    
    // Completion animation controller
    _completionController = AnimationController(
      duration: _accessibilityService.isReducedMotionEnabled 
          ? const Duration(milliseconds: 100)
          : AppDurations.taskCompletion,
      vsync: this,
    );
    
    // Swipe animation controller
    _swipeController = AnimationController(
      duration: _accessibilityService.isReducedMotionEnabled 
          ? const Duration(milliseconds: 100)
          : AppDurations.swipeAnimation,
      vsync: this,
    );
    
    // Focus handling for keyboard navigation
    _focusNode.addListener(_onFocusChanged);
    
    _completionAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut,
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
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isKeyboardActive = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update animations if necessary to avoid rebuilds
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _completionController.forward();
      } else {
        _completionController.reverse();
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskListItem &&
        other.task.id == widget.task.id &&
        other.task.isCompleted == widget.task.isCompleted &&
        other.task.title == widget.task.title &&
        other.task.dueDate == widget.task.dueDate &&
        other.category?.id == widget.category?.id;
  }

  @override
  int get hashCode => widget.task.id.hashCode;

  void _handleToggleComplete() {
    // Provide accessible haptic feedback
    _accessibilityService.provideFeedback(type: HapticFeedbackType.selectionClick);
    
    // Announce state change to screen reader
    final newState = widget.task.isCompleted ? 'uncompleted' : 'completed';
    _accessibilityService.announce('Task ${widget.task.title} $newState');
    
    // Add bounce animation for completion (respect reduced motion)
    if (!widget.task.isCompleted && !_accessibilityService.isReducedMotionEnabled) {
      _completionController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _completionController.reverse();
        });
      });
    }
    
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
    final isHighContrast = _accessibilityService.isHighContrastEnabled;
    
    // Color logic for visual hierarchy with high contrast support
    final backgroundColor = widget.task.isCompleted
        ? (isHighContrast 
            ? theme.colorScheme.surfaceVariant.withOpacity(0.8)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5))
        : isOverdue
            ? (isHighContrast 
                ? AppColors.error.withOpacity(0.2)
                : AppColors.error.withOpacity(0.1))
            : isDueToday
                ? (isHighContrast 
                    ? AppColors.warning.withOpacity(0.2)
                    : AppColors.warning.withOpacity(0.1))
                : theme.colorScheme.surface;
    
    final borderColor = widget.task.isCompleted
        ? (isHighContrast 
            ? AppColors.success.withOpacity(0.6)
            : AppColors.success.withOpacity(0.3))
        : isOverdue
            ? (isHighContrast 
                ? AppColors.error.withOpacity(0.6)
                : AppColors.error.withOpacity(0.3))
            : isDueToday
                ? (isHighContrast 
                    ? AppColors.warning.withOpacity(0.6)
                    : AppColors.warning.withOpacity(0.3))
                : Colors.transparent;

    // Enhanced border for keyboard focus
    final focusBorderColor = _isKeyboardActive 
        ? theme.colorScheme.primary
        : borderColor;

    // Create accessible semantic description
    final semanticLabel = _createSemanticLabel();
    final semanticHint = _createSemanticHint();

    return _accessibilityService.createFocusWrapper(
      focusNode: _focusNode,
      focusColor: theme.colorScheme.primary,
      borderWidth: 3.0,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: _accessibilityService.makeAccessible(
        semanticLabel: semanticLabel,
        semanticHint: semanticHint,
        isButton: true,
        isSelected: widget.task.isCompleted,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _completionAnimation,
          builder: (context, child) {
            final scale = _accessibilityService.isReducedMotionEnabled 
                ? 1.0 
                : _completionAnimation.value;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: widget.task.isCompleted ? 0.7 : 1.0,
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
                      border: Border.all(
                        color: focusBorderColor, 
                        width: _isKeyboardActive ? 3 : 1,
                      ),
                      boxShadow: isHighContrast ? [] : [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildKeyboardNavigableContent(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: isEdit ? Alignment.centerLeft : Alignment.centerRight,
          end: isEdit ? Alignment.centerRight : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedScale(
        scale: 1.0,
        duration: AppDurations.fast,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
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
      ),
    );
  }

  /// Build keyboard navigable content
  Widget _buildKeyboardNavigableContent() {
    if (widget.enableSwipeActions && !_isKeyboardActive) {
      return _buildSwipeWrapper();
    } else {
      return _buildTaskContent();
    }
  }

  /// Create comprehensive semantic label for screen readers
  String _createSemanticLabel() {
    final buffer = StringBuffer();
    
    // Task completion status
    buffer.write(widget.task.isCompleted ? 'Completed task: ' : 'Task: ');
    
    // Task title
    buffer.write(widget.task.title);
    
    // Task description if present
    if (widget.task.description != null && widget.task.description!.isNotEmpty) {
      buffer.write('. Description: ${widget.task.description}');
    }
    
    // Due date information
    if (widget.task.dueDateTimeDisplay != null) {
      buffer.write('. Due: ${widget.task.dueDateTimeDisplay}');
      
      if (widget.task.isOverdue) {
        buffer.write(' (Overdue)');
      } else if (widget.task.isDueToday) {
        buffer.write(' (Due today)');
      }
    }
    
    // Category information
    if (widget.showCategory && widget.category != null) {
      buffer.write('. Category: ${widget.category!.name}');
    }
    
    // Task source
    if (widget.task.source != TaskSource.manual) {
      buffer.write('. Created via ${widget.task.source.name}');
    }
    
    return buffer.toString();
  }

  /// Create semantic hint for screen reader interactions
  String _createSemanticHint() {
    final hints = <String>[];
    
    if (widget.task.isCompleted) {
      hints.add('Double tap to mark as incomplete');
    } else {
      hints.add('Double tap to mark as complete');
    }
    
    if (widget.onEdit != null) {
      hints.add('Swipe right to edit');
    }
    
    if (widget.enableSwipeActions) {
      hints.add('Swipe left to complete');
    }
    
    return hints.join('. ');
  }

  Widget _buildTaskContent() {
    return InkWell(
      onTap: widget.onTap,
      focusNode: _focusNode,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _accessibilityService.minTouchTargetSize,
        ),
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
                    style: (widget.task.isCompleted
                        ? AppTextStyles.withStrikethrough(AppTextStyles.taskTitle)
                        : AppTextStyles.taskTitle).copyWith(
                      fontSize: AppTextStyles.taskTitle.fontSize! * _accessibilityService.textScaleFactor,
                    ),
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
    final checkboxSize = _accessibilityService.minTouchTargetSize.clamp(24.0, 32.0);
    final iconSize = checkboxSize * 0.6;
    
    return Semantics(
      label: widget.task.isCompleted ? 'Task completed' : 'Task not completed',
      hint: 'Double tap to ${widget.task.isCompleted ? 'uncomplete' : 'complete'} task',
      button: true,
      toggled: widget.task.isCompleted,
      child: GestureDetector(
        onTap: _handleToggleComplete,
        child: Container(
          width: checkboxSize,
          height: checkboxSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: _accessibilityService.isReducedMotionEnabled 
                  ? const Duration(milliseconds: 50)
                  : AppDurations.fast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.task.isCompleted 
                    ? AppColors.success 
                    : Colors.transparent,
                border: Border.all(
                  color: widget.task.isCompleted 
                      ? AppColors.success 
                      : (_accessibilityService.isHighContrastEnabled
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.outline),
                  width: _accessibilityService.isHighContrastEnabled ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: widget.task.isCompleted
                  ? (_accessibilityService.isReducedMotionEnabled
                      ? Icon(
                          Icons.check,
                          size: iconSize,
                          color: Colors.white,
                        )
                      : TweenAnimationBuilder<double>(
                          duration: AppDurations.fast,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                Icons.check,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            );
                          },
                        ))
                  : null,
            ),
          ),
        ),
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