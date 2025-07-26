import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/task_provider.dart';
import '../../shared/widgets/widgets.dart';

/// Main task screen with list of tasks and floating voice button
/// Optimized for forgetful users with clear visual hierarchy
class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen>
    with TickerProviderStateMixin {
  bool _showCompletedTasks = false;
  Category? _selectedCategoryFilter;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingTasks = ref.watch(pendingTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final categories = ref.watch(categoriesProvider);
    final taskStats = ref.watch(taskStatsProvider);
    
    // Filter tasks by category if selected
    final filteredPendingTasks = _selectedCategoryFilter != null
        ? pendingTasks.where((task) => task.categoryId == _selectedCategoryFilter!.id).toList()
        : pendingTasks;
    
    final filteredCompletedTasks = _selectedCategoryFilter != null
        ? completedTasks.where((task) => task.categoryId == _selectedCategoryFilter!.id).toList()
        : completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
        actions: [
          // Category filter button
          IconButton(
            onPressed: _showCategoryFilter,
            icon: Icon(
              _selectedCategoryFilter != null 
                  ? Icons.filter_alt 
                  : Icons.filter_alt_outlined,
            ),
            tooltip: 'Filter by category',
          ),
          
          // Settings button
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: CustomScrollView(
          slivers: [
            // Task statistics summary
            SliverToBoxAdapter(
              child: _buildTaskSummary(taskStats),
            ),
            
            // Category filter chips (if no category selected)
            if (_selectedCategoryFilter == null)
              SliverToBoxAdapter(
                child: _buildCategoryFilter(categories),
              ),
            
            // Current category filter display
            if (_selectedCategoryFilter != null)
              SliverToBoxAdapter(
                child: _buildSelectedCategoryFilter(),
              ),
            
            // Pending tasks section
            if (filteredPendingTasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Pending Tasks',
                  '${filteredPendingTasks.length} task${filteredPendingTasks.length == 1 ? '' : 's'}',
                ),
              ),
              
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = filteredPendingTasks[index];
                    final category = categories.cast<Category?>()
                        .firstWhere((cat) => cat?.id == task.categoryId, orElse: () => null);
                    
                    return TaskListItem(
                      task: task,
                      category: category,
                      onTap: () => _editTask(task),
                      onToggleComplete: (updatedTask) {
                        ref.read(taskProvider.notifier).updateTask(updatedTask);
                      },
                      onEdit: () => _editTask(task),
                    );
                  },
                  childCount: filteredPendingTasks.length,
                ),
              ),
            ],
            
            // Completed tasks section
            SliverToBoxAdapter(
              child: _buildCompletedTasksToggle(filteredCompletedTasks.length),
            ),
            
            if (_showCompletedTasks && filteredCompletedTasks.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = filteredCompletedTasks[index];
                    final category = categories.cast<Category?>()
                        .firstWhere((cat) => cat?.id == task.categoryId, orElse: () => null);
                    
                    return TaskListItem(
                      task: task,
                      category: category,
                      onTap: () => _editTask(task),
                      onToggleComplete: (updatedTask) {
                        ref.read(taskProvider.notifier).updateTask(updatedTask);
                      },
                      showCategory: false, // Less visual clutter for completed tasks
                    );
                  },
                  childCount: filteredCompletedTasks.length,
                ),
              ),
            
            // Empty state
            if (filteredPendingTasks.isEmpty && 
                (!_showCompletedTasks || filteredCompletedTasks.isEmpty))
              SliverFillRemaining(
                child: _buildEmptyState(),
              ),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTaskSummary(TaskStats stats) {
    if (stats.total == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              stats.total.toString(),
              AppColors.info,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Pending',
              stats.pending.toString(),
              AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Completed',
              stats.completed.toString(),
              AppColors.success,
            ),
          ),
          if (stats.overdue > 0)
            Expanded(
              child: _buildStatItem(
                'Overdue',
                stats.overdue.toString(),
                AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: CategoryChipList(
        categories: [
          // Add "All" category
          Category(
            id: 'all',
            name: 'All',
            icon: '📋',
            color: AppColors.primary,
            createdAt: DateTime.now(),
          ),
          ...categories,
        ],
        selectedCategory: _selectedCategoryFilter,
        onCategorySelected: (category) {
          setState(() {
            _selectedCategoryFilter = category.id == 'all' ? null : category;
          });
        },
        isCompact: true,
      ),
    );
  }

  Widget _buildSelectedCategoryFilter() {
    if (_selectedCategoryFilter == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _selectedCategoryFilter!.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: _selectedCategoryFilter!.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CategoryDisplay(
            category: _selectedCategoryFilter!,
            isCompact: true,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedCategoryFilter = null),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear filter'),
            style: TextButton.styleFrom(
              foregroundColor: _selectedCategoryFilter!.color,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksToggle(int completedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'Completed Tasks',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '($completedCount)',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: completedCount > 0 
                ? () => setState(() => _showCompletedTasks = !_showCompletedTasks)
                : null,
            icon: Icon(_showCompletedTasks 
                ? Icons.keyboard_arrow_up 
                : Icons.keyboard_arrow_down),
            label: Text(_showCompletedTasks ? 'Hide' : 'Show'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategoryFilter != null
                  ? Icons.filter_alt_off
                  : Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _selectedCategoryFilter != null
                  ? 'No tasks in this category'
                  : 'No tasks yet',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedCategoryFilter != null
                  ? 'Try selecting a different category or clear the filter'
                  : 'Tap the voice button below to add your first task',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _createTask,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return LargeVoiceButton(
      onPressed: _handleVoiceInput,
      label: 'Add Task',
      isListening: false, // TODO: Connect to voice service
      isProcessing: false, // TODO: Connect to voice service
    );
  }

  void _createTask() {
    _showTaskInputModal();
  }

  void _editTask(Task task) {
    _showTaskInputModal(task: task);
  }

  void _handleVoiceInput() {
    // TODO: Implement voice input functionality
    // For now, just show the task input modal
    _showTaskInputModal(isVoiceInput: true);
  }

  void _showTaskInputModal({Task? task, bool isVoiceInput = false}) {
    final categories = ref.read(categoriesProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskInputComponent(
        initialTask: task,
        categories: categories,
        isVoiceInput: isVoiceInput,
        onTaskCreated: (newTask) {
          ref.read(taskProvider.notifier).addTask(newTask);
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${newTask.title}" created'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(taskProvider.notifier).deleteTask(newTask.id);
                },
              ),
            ),
          );
        },
        onTaskUpdated: (updatedTask) {
          ref.read(taskProvider.notifier).updateTask(updatedTask);
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${updatedTask.title}" updated'),
              backgroundColor: AppColors.info,
            ),
          );
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showCategoryFilter() {
    final categories = ref.read(categoriesProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            CategoryChipWrap(
              categories: [
                Category(
                  id: 'all',
                  name: 'All Tasks',
                  icon: '📋',
                  color: AppColors.primary,
                  createdAt: DateTime.now(),
                ),
                ...categories,
              ],
              selectedCategory: _selectedCategoryFilter,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategoryFilter = category.id == 'all' ? null : category;
                });
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    // TODO: Implement settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings coming soon!'),
      ),
    );
  }

  Future<void> _refreshTasks() async {
    // TODO: Implement refresh functionality
    // For now, just add a delay to simulate refresh
    await Future.delayed(const Duration(seconds: 1));
  }
}