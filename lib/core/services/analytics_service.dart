import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../shared/models/models.dart';
import '../repositories/repositories.dart';

/// Advanced analytics service for task insights and productivity tracking
/// Provides comprehensive analytics with performance optimizations
class AnalyticsService {
  final TaskRepository _taskRepository;
  final CategoryRepository _categoryRepository;
  
  // Cache for analytics data
  final Map<String, AnalyticsCacheEntry> _analyticsCache = {};
  Timer? _cacheRefreshTimer;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  AnalyticsService({
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) : _taskRepository = taskRepository,
       _categoryRepository = categoryRepository {
    _startCacheRefresh();
  }

  /// Start periodic cache refresh
  void _startCacheRefresh() {
    _cacheRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _refreshCriticalAnalytics();
    });
  }

  /// Refresh critical analytics in background
  Future<void> _refreshCriticalAnalytics() async {
    try {
      // Pre-compute frequently accessed analytics
      await getProductivityInsights(useCache: false);
      await getTaskCompletionTrends(days: 30, useCache: false);
      await getCategoryDistribution(useCache: false);
    } catch (e) {
      debugPrint('Failed to refresh analytics cache: $e');
    }
  }

  /// Get comprehensive productivity insights
  Future<ProductivityInsights> getProductivityInsights({
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    final cacheKey = 'productivity_${startDate?.millisecondsSinceEpoch}_${endDate?.millisecondsSinceEpoch}';
    
    if (useCache && _analyticsCache.containsKey(cacheKey)) {
      final cached = _analyticsCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
        return cached.data as ProductivityInsights;
      }
    }

    try {
      final allTasks = await _taskRepository.getAllTasks();
      final filteredTasks = _filterTasksByDateRange(allTasks, startDate, endDate);
      
      final insights = await _calculateProductivityInsights(filteredTasks);
      
      if (useCache) {
        _analyticsCache[cacheKey] = AnalyticsCacheEntry(
          data: insights,
          timestamp: DateTime.now(),
        );
      }
      
      return insights;
    } catch (e) {
      debugPrint('Failed to get productivity insights: $e');
      return ProductivityInsights.empty();
    }
  }

  /// Calculate detailed productivity insights
  Future<ProductivityInsights> _calculateProductivityInsights(List<Task> tasks) async {
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final overdueTasks = tasks.where((t) => t.isOverdue).toList();
    
    // Completion rate
    final completionRate = tasks.isNotEmpty 
        ? (completedTasks.length / tasks.length) * 100 
        : 0.0;
    
    // Average completion time
    final avgCompletionTime = await _calculateAverageCompletionTime(completedTasks);
    
    // Source distribution
    final sourceDistribution = _calculateSourceDistribution(tasks);
    
    // Priority distribution
    final priorityDistribution = _calculatePriorityDistribution(tasks);
    
    // Daily productivity score (0-100)
    final productivityScore = _calculateProductivityScore(
      completionRate: completionRate,
      overdueRatio: overdueTasks.length / tasks.length,
      avgCompletionTime: avgCompletionTime,
    );
    
    // Weekly trends
    final weeklyTrends = await _calculateWeeklyTrends(tasks);
    
    // Category performance
    final categoryPerformance = await _calculateCategoryPerformance(tasks);
    
    return ProductivityInsights(
      totalTasks: tasks.length,
      completedTasks: completedTasks.length,
      pendingTasks: pendingTasks.length,
      overdueTasks: overdueTasks.length,
      completionRate: completionRate,
      averageCompletionTimeHours: avgCompletionTime,
      productivityScore: productivityScore,
      sourceDistribution: sourceDistribution,
      priorityDistribution: priorityDistribution,
      weeklyTrends: weeklyTrends,
      categoryPerformance: categoryPerformance,
    );
  }

  /// Get task completion trends over time
  Future<List<CompletionTrend>> getTaskCompletionTrends({
    int days = 30,
    bool useCache = true,
  }) async {
    final cacheKey = 'completion_trends_$days';
    
    if (useCache && _analyticsCache.containsKey(cacheKey)) {
      final cached = _analyticsCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
        return cached.data as List<CompletionTrend>;
      }
    }

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final allTasks = await _taskRepository.getAllTasks();
      
      final trends = <CompletionTrend>[];
      
      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayTasks = allTasks.where((task) {
          return task.updatedAt.isAfter(dayStart) && 
                 task.updatedAt.isBefore(dayEnd);
        }).toList();
        
        final completedCount = dayTasks.where((t) => t.isCompleted).length;
        final createdCount = dayTasks.where((task) {
          return task.createdAt.isAfter(dayStart) && 
                 task.createdAt.isBefore(dayEnd);
        }).length;
        
        trends.add(CompletionTrend(
          date: dayStart,
          completedTasks: completedCount,
          createdTasks: createdCount,
          completionRate: createdCount > 0 ? (completedCount / createdCount) * 100 : 0,
        ));
      }
      
      if (useCache) {
        _analyticsCache[cacheKey] = AnalyticsCacheEntry(
          data: trends,
          timestamp: DateTime.now(),
        );
      }
      
      return trends;
    } catch (e) {
      debugPrint('Failed to get completion trends: $e');
      return [];
    }
  }

  /// Get category distribution and performance
  Future<CategoryAnalytics> getCategoryDistribution({bool useCache = true}) async {
    const cacheKey = 'category_distribution';
    
    if (useCache && _analyticsCache.containsKey(cacheKey)) {
      final cached = _analyticsCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
        return cached.data as CategoryAnalytics;
      }
    }

    try {
      final [tasks, categories] = await Future.wait([
        _taskRepository.getAllTasks(),
        _categoryRepository.getAllCategories(),
      ]);
      
      final distribution = <CategoryDistribution>[];
      
      for (final category in categories) {
        final categoryTasks = tasks.where((t) => t.categoryId == category.id.toString()).toList();
        final completedTasks = categoryTasks.where((t) => t.isCompleted).length;
        final overdueTask = categoryTasks.where((t) => t.isOverdue).length;
        
        distribution.add(CategoryDistribution(
          categoryId: category.id.toString(),
          categoryName: category.name,
          totalTasks: categoryTasks.length,
          completedTasks: completedTasks,
          pendingTasks: categoryTasks.length - completedTasks,
          overdueTasks: overdueTask,
          completionRate: categoryTasks.isNotEmpty 
              ? (completedTasks / categoryTasks.length) * 100 
              : 0.0,
        ));
      }
      
      // Sort by total tasks descending
      distribution.sort((a, b) => b.totalTasks.compareTo(a.totalTasks));
      
      final analytics = CategoryAnalytics(
        distribution: distribution,
        mostActiveCategory: distribution.isNotEmpty ? distribution.first : null,
        highestCompletionRate: distribution.isNotEmpty 
            ? distribution.reduce((a, b) => a.completionRate > b.completionRate ? a : b)
            : null,
      );
      
      if (useCache) {
        _analyticsCache[cacheKey] = AnalyticsCacheEntry(
          data: analytics,
          timestamp: DateTime.now(),
        );
      }
      
      return analytics;
    } catch (e) {
      debugPrint('Failed to get category distribution: $e');
      return CategoryAnalytics.empty();
    }
  }

  /// Get task timing insights
  Future<TimingInsights> getTimingInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allTasks = await _taskRepository.getAllTasks();
      final filteredTasks = _filterTasksByDateRange(allTasks, startDate, endDate);
      
      return _calculateTimingInsights(filteredTasks);
    } catch (e) {
      debugPrint('Failed to get timing insights: $e');
      return TimingInsights.empty();
    }
  }

  /// Get habit analysis and patterns
  Future<HabitAnalysis> getHabitAnalysis({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final allTasks = await _taskRepository.getAllTasks();
      
      final recentTasks = allTasks.where((task) {
        return task.createdAt.isAfter(startDate);
      }).toList();
      
      return _calculateHabitAnalysis(recentTasks);
    } catch (e) {
      debugPrint('Failed to get habit analysis: $e');
      return HabitAnalysis.empty();
    }
  }

  /// Helper methods
  
  List<Task> _filterTasksByDateRange(List<Task> tasks, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return tasks;
    
    return tasks.where((task) {
      if (startDate != null && task.createdAt.isBefore(startDate)) return false;
      if (endDate != null && task.createdAt.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  Future<double> _calculateAverageCompletionTime(List<Task> completedTasks) async {
    if (completedTasks.isEmpty) return 0.0;
    
    var totalHours = 0.0;
    var validTasks = 0;
    
    for (final task in completedTasks) {
      if (task.dueDate != null) {
        final completionTime = task.updatedAt.difference(task.createdAt).inHours;
        if (completionTime > 0) {
          totalHours += completionTime;
          validTasks++;
        }
      }
    }
    
    return validTasks > 0 ? totalHours / validTasks : 0.0;
  }

  Map<TaskSource, int> _calculateSourceDistribution(List<Task> tasks) {
    final distribution = <TaskSource, int>{};
    
    for (final source in TaskSource.values) {
      distribution[source] = tasks.where((t) => t.source == source).length;
    }
    
    return distribution;
  }

  Map<TaskPriority, int> _calculatePriorityDistribution(List<Task> tasks) {
    final distribution = <TaskPriority, int>{};
    
    for (final priority in TaskPriority.values) {
      distribution[priority] = tasks.where((t) => t.priority == priority).length;
    }
    
    return distribution;
  }

  double _calculateProductivityScore({
    required double completionRate,
    required double overdueRatio,
    required double avgCompletionTime,
  }) {
    // Base score from completion rate (0-40 points)
    var score = completionRate * 0.4;
    
    // Penalty for overdue tasks (up to -20 points)
    score -= overdueRatio * 20;
    
    // Bonus for fast completion (up to +20 points)
    if (avgCompletionTime > 0 && avgCompletionTime < 24) {
      score += math.max(0, 20 - avgCompletionTime);
    }
    
    // Ensure score is between 0 and 100
    return math.max(0, math.min(100, score));
  }

  Future<List<WeeklyTrend>> _calculateWeeklyTrends(List<Task> tasks) async {
    final trends = <WeeklyTrend>[];
    final now = DateTime.now();
    
    for (int week = 0; week < 4; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final weekTasks = tasks.where((task) {
        return task.createdAt.isAfter(weekStart) && task.createdAt.isBefore(weekEnd);
      }).toList();
      
      final completedCount = weekTasks.where((t) => t.isCompleted).length;
      
      trends.add(WeeklyTrend(
        weekStart: weekStart,
        totalTasks: weekTasks.length,
        completedTasks: completedCount,
        completionRate: weekTasks.isNotEmpty ? (completedCount / weekTasks.length) * 100 : 0,
      ));
    }
    
    return trends.reversed.toList();
  }

  Future<List<CategoryPerformance>> _calculateCategoryPerformance(List<Task> tasks) async {
    final categories = await _categoryRepository.getAllCategories();
    final performance = <CategoryPerformance>[];
    
    for (final category in categories) {
      final categoryTasks = tasks.where((t) => t.categoryId == category.id.toString()).toList();
      final completedTasks = categoryTasks.where((t) => t.isCompleted).length;
      final avgTime = await _calculateAverageCompletionTime(
        categoryTasks.where((t) => t.isCompleted).toList(),
      );
      
      performance.add(CategoryPerformance(
        categoryId: category.id.toString(),
        categoryName: category.name,
        totalTasks: categoryTasks.length,
        completionRate: categoryTasks.isNotEmpty ? (completedTasks / categoryTasks.length) * 100 : 0,
        averageCompletionTime: avgTime,
      ));
    }
    
    return performance;
  }

  TimingInsights _calculateTimingInsights(List<Task> tasks) {
    final tasksWithTime = tasks.where((t) => t.dueTime != null).toList();
    
    if (tasksWithTime.isEmpty) {
      return TimingInsights.empty();
    }
    
    // Group by hour of day
    final hourDistribution = <int, int>{};
    final hourCompletion = <int, int>{};
    
    for (final task in tasksWithTime) {
      final hour = task.dueTime!.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
      
      if (task.isCompleted) {
        hourCompletion[hour] = (hourCompletion[hour] ?? 0) + 1;
      }
    }
    
    // Find peak hours
    final sortedHours = hourDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final peakHour = sortedHours.isNotEmpty ? sortedHours.first.key : 9;
    
    // Calculate best performance hour
    var bestHour = 9;
    var bestRate = 0.0;
    
    for (final entry in hourDistribution.entries) {
      final hour = entry.key;
      final total = entry.value;
      final completed = hourCompletion[hour] ?? 0;
      final rate = total > 0 ? (completed / total) * 100 : 0;
      
      if (rate > bestRate) {
        bestRate = rate;
        bestHour = hour;
      }
    }
    
    return TimingInsights(
      peakProductivityHour: peakHour,
      bestCompletionRateHour: bestHour,
      hourlyDistribution: hourDistribution,
      hourlyCompletionRates: hourCompletion.map((k, v) => MapEntry(k, 
        hourDistribution[k] != null ? (v / hourDistribution[k]!) * 100 : 0)),
    );
  }

  HabitAnalysis _calculateHabitAnalysis(List<Task> tasks) {
    // Common patterns analysis
    final titleWords = <String, int>{};
    final morningTasks = tasks.where((t) => 
      t.dueTime != null && t.dueTime!.hour < 12).length;
    final eveningTasks = tasks.where((t) => 
      t.dueTime != null && t.dueTime!.hour >= 18).length;
    
    // Extract common words from task titles
    for (final task in tasks) {
      final words = task.title.toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((w) => w.length > 3);
      
      for (final word in words) {
        titleWords[word] = (titleWords[word] ?? 0) + 1;
      }
    }
    
    // Get most common words
    final commonWords = titleWords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final patterns = <String>[];
    
    if (morningTasks > tasks.length * 0.3) {
      patterns.add('Morning person - prefers early tasks');
    }
    if (eveningTasks > tasks.length * 0.3) {
      patterns.add('Evening person - active in evenings');
    }
    if (commonWords.isNotEmpty) {
      patterns.add('Frequently creates "${commonWords.first.key}" tasks');
    }
    
    return HabitAnalysis(
      commonPatterns: patterns,
      frequentWords: commonWords.take(5).map((e) => e.key).toList(),
      preferredTimeSlots: _getPreferredTimeSlots(tasks),
      averageTasksPerDay: tasks.length / 30,
    );
  }

  List<String> _getPreferredTimeSlots(List<Task> tasks) {
    final slots = <String>[];
    final tasksWithTime = tasks.where((t) => t.dueTime != null).toList();
    
    if (tasksWithTime.isEmpty) return slots;
    
    final morning = tasksWithTime.where((t) => t.dueTime!.hour < 12).length;
    final afternoon = tasksWithTime.where((t) => t.dueTime!.hour >= 12 && t.dueTime!.hour < 18).length;
    final evening = tasksWithTime.where((t) => t.dueTime!.hour >= 18).length;
    
    final total = tasksWithTime.length;
    
    if (morning / total > 0.4) slots.add('Morning (6AM-12PM)');
    if (afternoon / total > 0.4) slots.add('Afternoon (12PM-6PM)');
    if (evening / total > 0.4) slots.add('Evening (6PM-12AM)');
    
    return slots;
  }

  /// Clear analytics cache
  void clearCache() {
    _analyticsCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _analyticsCache.length,
      'cacheKeys': _analyticsCache.keys.toList(),
      'oldestEntry': _analyticsCache.values.isNotEmpty 
          ? _analyticsCache.values.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
    };
  }

  /// Dispose resources
  void dispose() {
    _cacheRefreshTimer?.cancel();
    clearCache();
  }
}

/// Analytics data models

class ProductivityInsights {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionRate;
  final double averageCompletionTimeHours;
  final double productivityScore;
  final Map<TaskSource, int> sourceDistribution;
  final Map<TaskPriority, int> priorityDistribution;
  final List<WeeklyTrend> weeklyTrends;
  final List<CategoryPerformance> categoryPerformance;

  const ProductivityInsights({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.averageCompletionTimeHours,
    required this.productivityScore,
    required this.sourceDistribution,
    required this.priorityDistribution,
    required this.weeklyTrends,
    required this.categoryPerformance,
  });

  factory ProductivityInsights.empty() {
    return const ProductivityInsights(
      totalTasks: 0,
      completedTasks: 0,
      pendingTasks: 0,
      overdueTasks: 0,
      completionRate: 0.0,
      averageCompletionTimeHours: 0.0,
      productivityScore: 0.0,
      sourceDistribution: {},
      priorityDistribution: {},
      weeklyTrends: [],
      categoryPerformance: [],
    );
  }
}

class CompletionTrend {
  final DateTime date;
  final int completedTasks;
  final int createdTasks;
  final double completionRate;

  const CompletionTrend({
    required this.date,
    required this.completedTasks,
    required this.createdTasks,
    required this.completionRate,
  });
}

class CategoryAnalytics {
  final List<CategoryDistribution> distribution;
  final CategoryDistribution? mostActiveCategory;
  final CategoryDistribution? highestCompletionRate;

  const CategoryAnalytics({
    required this.distribution,
    this.mostActiveCategory,
    this.highestCompletionRate,
  });

  factory CategoryAnalytics.empty() {
    return const CategoryAnalytics(distribution: []);
  }
}

class CategoryDistribution {
  final String categoryId;
  final String categoryName;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionRate;

  const CategoryDistribution({
    required this.categoryId,
    required this.categoryName,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
  });
}

class TimingInsights {
  final int peakProductivityHour;
  final int bestCompletionRateHour;
  final Map<int, int> hourlyDistribution;
  final Map<int, double> hourlyCompletionRates;

  const TimingInsights({
    required this.peakProductivityHour,
    required this.bestCompletionRateHour,
    required this.hourlyDistribution,
    required this.hourlyCompletionRates,
  });

  factory TimingInsights.empty() {
    return const TimingInsights(
      peakProductivityHour: 9,
      bestCompletionRateHour: 9,
      hourlyDistribution: {},
      hourlyCompletionRates: {},
    );
  }
}

class HabitAnalysis {
  final List<String> commonPatterns;
  final List<String> frequentWords;
  final List<String> preferredTimeSlots;
  final double averageTasksPerDay;

  const HabitAnalysis({
    required this.commonPatterns,
    required this.frequentWords,
    required this.preferredTimeSlots,
    required this.averageTasksPerDay,
  });

  factory HabitAnalysis.empty() {
    return const HabitAnalysis(
      commonPatterns: [],
      frequentWords: [],
      preferredTimeSlots: [],
      averageTasksPerDay: 0.0,
    );
  }
}

class WeeklyTrend {
  final DateTime weekStart;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  const WeeklyTrend({
    required this.weekStart,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });
}

class CategoryPerformance {
  final String categoryId;
  final String categoryName;
  final int totalTasks;
  final double completionRate;
  final double averageCompletionTime;

  const CategoryPerformance({
    required this.categoryId,
    required this.categoryName,
    required this.totalTasks,
    required this.completionRate,
    required this.averageCompletionTime,
  });
}

class AnalyticsCacheEntry {
  final dynamic data;
  final DateTime timestamp;

  const AnalyticsCacheEntry({
    required this.data,
    required this.timestamp,
  });
}