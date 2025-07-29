import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/task.dart';
import '../../shared/widgets/task_list_item.dart';
import '../../shared/widgets/widgets.dart';
import '../tasks/providers/task_providers.dart';
import 'providers/calendar_providers.dart';
import 'widgets/calendar_widget.dart';
import 'utils/date_time_utils.dart';

/// Main calendar screen showing calendar view and tasks for selected date
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarStateProvider);
    final selectedDate = calendarState.selectedDate;
    final tasksForDate = ref.watch(tasksForSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          // Today button
          TextButton(
            onPressed: () =>
                ref.read(calendarStateProvider.notifier).goToToday(),
            child: const Text('Today'),
          ),

          // View mode toggle
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (mode) {
              ref.read(calendarStateProvider.notifier).updateViewMode(mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarViewMode.month,
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('Month View'),
                ),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.week,
                child: ListTile(
                  leading: Icon(Icons.view_week),
                  title: Text('Week View'),
                ),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.agenda,
                child: ListTile(
                  leading: Icon(Icons.list),
                  title: Text('Agenda View'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Agenda', icon: Icon(Icons.list)),
            Tab(text: 'Tasks', icon: Icon(Icons.task_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Calendar Tab
          _buildCalendarTab(context, selectedDate, tasksForDate),

          // Agenda Tab
          _buildAgendaTab(context),

          // Tasks Tab
          _buildTasksTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTaskForSelectedDate(context, selectedDate),
        tooltip:
            'Add task for ${DateTimeUtils.formatDateForDisplay(selectedDate)}',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build calendar tab with calendar widget and selected date tasks
  Widget _buildCalendarTab(
      BuildContext context, DateTime selectedDate, List<Task> tasksForDate) {
    return Column(
      children: [
        // Calendar widget
        Container(
          margin: const EdgeInsets.all(AppSpacing.medium),
          child: const CalendarWidget(),
        ),

        // Divider
        const Divider(height: 1),

        // Selected date header
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Tasks for ${DateTimeUtils.formatDateForDisplay(selectedDate)}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (tasksForDate.isNotEmpty)
                Chip(
                  label: Text('${tasksForDate.length}'),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
            ],
          ),
        ),

        // Tasks for selected date
        Expanded(
          child: _buildTaskList(tasksForDate, selectedDate),
        ),
      ],
    );
  }

  /// Build agenda tab with chronological task view
  Widget _buildAgendaTab(BuildContext context) {
    final upcomingTasks = ref.watch(upcomingTasksProvider);

    return upcomingTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: AppSpacing.medium),
                Text('No upcoming tasks'),
              ],
            ),
          );
        }

        // Group tasks by date
        final Map<DateTime, List<Task>> tasksByDate = {};
        for (final task in tasks) {
          if (task.dueDate != null) {
            final dateKey = DateTime(
                task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
            tasksByDate.putIfAbsent(dateKey, () => []).add(task);
          }
        }

        final sortedDates = tasksByDate.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dateTasks = tasksByDate[date]!;

            return _buildAgendaDateSection(date, dateTasks);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading agenda: $error'),
      ),
    );
  }

  /// Build tasks tab with all tasks view
  Widget _buildTasksTab(BuildContext context) {
    final allTasks = ref.watch(allTasksProvider);

    return allTasks.when(
      data: (tasks) => _buildTaskList(tasks, null),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading tasks: $error'),
      ),
    );
  }

  /// Build agenda date section
  Widget _buildAgendaDateSection(DateTime date, List<Task> tasks) {
    final isToday = DateTimeUtils.isToday(date);
    final isPast = DateTimeUtils.isPastDay(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : isPast
                          ? Colors.grey.withOpacity(0.3)
                          : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.small),
                ),
                child: Text(
                  DateTimeUtils.formatDateForDisplay(date),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isToday
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Chip(
                label: Text('${tasks.length}'),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),

        // Tasks for this date
        ...tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: TaskListItem(task: task),
            )),

        const SizedBox(height: AppSpacing.medium),
      ],
    );
  }

  /// Build task list
  Widget _buildTaskList(List<Task> tasks, DateTime? filterDate) {
    if (tasks.isEmpty) {
      final message = filterDate != null
          ? 'No tasks for ${DateTimeUtils.formatDateForDisplay(filterDate)}'
          : 'No tasks found';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey,
              ),
            ),
            if (filterDate != null) ...[
              const SizedBox(height: AppSpacing.medium),
              ElevatedButton.icon(
                onPressed: () =>
                    _createTaskForSelectedDate(context, filterDate),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: TaskListItem(task: task),
        );
      },
    );
  }

  /// Create task for selected date
  void _createTaskForSelectedDate(BuildContext context, DateTime selectedDate) {
    // TODO: Navigate to task creation screen with pre-filled date
    // For now, we'll use a simple dialog
    showDialog(
      context: context,
      builder: (context) => TaskCreationDialog(initialDate: selectedDate),
    );
  }
}

/// Quick task creation dialog
class TaskCreationDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const TaskCreationDialog({
    super.key,
    this.initialDate,
  });

  @override
  ConsumerState<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends ConsumerState<TaskCreationDialog> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategoryId = 'personal';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          'Add Task for ${widget.initialDate != null ? DateTimeUtils.formatDateForDisplay(widget.initialDate!) : 'Today'}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'Enter task description',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.medium),

            // Category selection - simplified for now
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: Category.getDefaultCategories().map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Text(category.icon),
                      const SizedBox(width: AppSpacing.small),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final taskOps = ref.read(taskOperationsProvider);

      await taskOps.createTask(
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId,
        dueDate: widget.initialDate,
        source: TaskSource.calendar,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: $e')),
        );
      }
    }
  }
}

/// Provider for upcoming tasks (next 30 days)
final upcomingTasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final now = DateTime.now();
  final future = now.add(const Duration(days: 30));

  return await repository.getTasksByDateRange(now, future);
});
