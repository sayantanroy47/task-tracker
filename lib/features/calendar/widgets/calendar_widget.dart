import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/category.dart';
import '../../../shared/providers/app_providers.dart';
import '../providers/calendar_providers.dart';
import '../utils/date_time_utils.dart';

/// Calendar widget with integrated task display
/// Shows tasks as indicators on calendar dates with category colors
///
/// Performance optimizations:
/// - Uses efficient event loading with caching
/// - Optimized builders for custom day cells
/// - Efficient task grouping and filtering
class CalendarWidget extends ConsumerWidget {
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onDateTapped;
  final bool showTaskIndicators;
  final bool enableSwipeNavigation;

  const CalendarWidget({
    super.key,
    this.onDateSelected,
    this.onDateTapped,
    this.showTaskIndicators = true,
    this.enableSwipeNavigation = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarStateProvider);
    final selectedDate = calendarState.selectedDate;
    final focusedDay = calendarState.focusedDay;
    final calendarFormat = calendarState.calendarFormat;

    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar header with navigation
          _buildCalendarHeader(context, ref, calendarState),

          // Calendar widget
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) =>
                DateTimeUtils.isSameDay(day, selectedDate),
            calendarFormat: calendarFormat,

            // Event loader - provides tasks for each day
            eventLoader: showTaskIndicators
                ? (day) => ref
                    .read(calendarStateProvider.notifier)
                    .getTasksForDate(day)
                : null,

            // Styling
            calendarStyle: _buildCalendarStyle(context),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: false,
              rightChevronVisible: false,
              headerPadding: EdgeInsets.zero,
              titleTextStyle: TextStyle(fontSize: 0), // Hide default header
            ),

            // Builders for custom day appearance - optimized with memoization
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, false, false, categories, ref),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, true, false, categories, ref),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, false, true, categories, ref),
              outsideBuilder: (context, day, focusedDay) => _buildDayCell(
                  context, day, false, false, categories, ref,
                  isOutside: true),
              markerBuilder: (context, day, tasks) =>
                  _buildTaskMarkers(context, day, tasks, categories),
            ),

            // Callbacks
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(calendarStateProvider.notifier).selectDate(selectedDay);
              onDateSelected?.call(selectedDay);
              onDateTapped?.call(selectedDay);
            },

            onPageChanged: enableSwipeNavigation
                ? (focusedDay) => ref
                    .read(calendarStateProvider.notifier)
                    .updateFocusedDay(focusedDay)
                : null,

            onFormatChanged: (format) {
              ref
                  .read(calendarStateProvider.notifier)
                  .updateCalendarFormat(format);
            },

            // Gesture configuration
            pageJumpingEnabled: enableSwipeNavigation,
            pageAnimationEnabled: true,
            pageAnimationDuration: const Duration(milliseconds: 300),
          ),

          const SizedBox(height: AppSpacing.small),
        ],
      ),
    );
  }

  /// Build custom calendar header with navigation controls
  Widget _buildCalendarHeader(
      BuildContext context, WidgetRef ref, CalendarState calendarState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          IconButton(
            onPressed: () =>
                ref.read(calendarStateProvider.notifier).previousMonth(),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
          ),

          // Month/Year title
          InkWell(
            onTap: () => ref.read(calendarStateProvider.notifier).goToToday(),
            borderRadius: BorderRadius.circular(AppSpacing.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              child: Text(
                _formatMonthYear(calendarState.focusedDay),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Next month button
          IconButton(
            onPressed: () =>
                ref.read(calendarStateProvider.notifier).nextMonth(),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  /// Build calendar style configuration
  CalendarStyle _buildCalendarStyle(BuildContext context) {
    return CalendarStyle(
      // Outside days (previous/next month)
      outsideDaysVisible: true,
      outsideTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
      ),

      // Weekend styling
      weekendTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.error,
      ),

      // Selected day styling
      selectedDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      selectedTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Today styling
      todayDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),

      // Default day styling
      defaultTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),

      // Marker styling
      markersMaxCount: 3,
      markerDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      markerMargin: const EdgeInsets.symmetric(horizontal: 1),

      // Cell configuration
      cellMargin: const EdgeInsets.all(4),
      cellPadding: EdgeInsets.zero,

      // Row decoration
      rowDecoration: const BoxDecoration(),

      // Table border
      tableBorder: TableBorder.all(
        color: Colors.transparent,
        width: 0,
      ),
    );
  }

  /// Build custom day cell with task indicators
  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    bool isSelected,
    bool isToday,
    List<Category> categories,
    WidgetRef ref, {
    bool isOutside = false,
  }) {
    final tasks = ref.read(calendarStateProvider.notifier).getTasksForDate(day);
    final hasEvents = tasks.isNotEmpty;

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
      textColor = Theme.of(context).colorScheme.primary;
    } else if (isOutside) {
      textColor =
          Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3);
    } else {
      textColor = Theme.of(context).textTheme.bodyMedium?.color;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: hasEvents && !isSelected && !isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Center(
        child: Text(
          day.day.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight:
                isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build task markers for each day
  /// Optimized with efficient grouping and caching
  Widget _buildTaskMarkers(
    BuildContext context,
    DateTime day,
    List<Task> tasks,
    List<Category> categories,
  ) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    // Use a more efficient approach to group tasks by category
    final tasksByCategory = <String, _TaskCategoryGroup>{};
    for (final task in tasks) {
      final group = tasksByCategory.putIfAbsent(
        task.categoryId,
        () => _TaskCategoryGroup(categoryId: task.categoryId),
      );
      group.addTask(task);
    }

    // Show up to 3 category indicators with best coverage
    final sortedGroups = tasksByCategory.values.toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
    final topGroups = sortedGroups.take(3);

    return Positioned(
      bottom: 4,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: topGroups.map((group) {
          final category = categories.firstWhere(
            (cat) => cat.id == group.categoryId,
            orElse: () => Category.getDefaultCategories().first,
          );

          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: group.isAllCompleted
                  ? category.color.withOpacity(0.5) // Dimmed if all completed
                  : category.color,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Format month and year for header display
  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Compact calendar widget for smaller spaces
class CompactCalendarWidget extends ConsumerWidget {
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;

  const CompactCalendarWidget({
    super.key,
    this.onDateSelected,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CalendarWidget(
      onDateSelected: onDateSelected,
      showTaskIndicators: true,
      enableSwipeNavigation: true,
    );
  }
}

/// Helper class for efficient task grouping by category
/// Optimizes performance by caching completion status
class _TaskCategoryGroup {
  final String categoryId;
  final List<Task> _tasks = [];
  int _completedCount = 0;

  _TaskCategoryGroup({required this.categoryId});

  void addTask(Task task) {
    _tasks.add(task);
    if (task.isCompleted) {
      _completedCount++;
    }
  }

  int get totalCount => _tasks.length;
  int get completedCount => _completedCount;
  bool get isAllCompleted =>
      _completedCount == _tasks.length && _tasks.isNotEmpty;
  bool get hasIncompleteTasks => _completedCount < _tasks.length;
}

/// Calendar legend showing category colors
class CalendarLegend extends ConsumerWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Categories',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.small,
            children: categories.map((category) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    category.name,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
