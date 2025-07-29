import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shared/models/models.dart';
import '../repositories/repositories.dart';

/// Advanced search and filtering service for tasks
/// Provides fast search with multiple criteria, smart suggestions, and performance optimizations
class SearchService {
  final TaskRepository _taskRepository;
  final CategoryRepository _categoryRepository;

  // Performance optimizations
  final Map<String, SearchCacheEntry> _searchCache = {};
  final Set<String> _searchTermsCache = {};
  Timer? _cacheCleanupTimer;
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  SearchService({
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  })  : _taskRepository = taskRepository,
        _categoryRepository = categoryRepository {
    _initializeSearchTermsCache();
    _startCacheCleanup();
  }

  /// Initialize search terms cache for autocomplete
  Future<void> _initializeSearchTermsCache() async {
    try {
      final tasks = await _taskRepository.getAllTasks();
      for (final task in tasks) {
        _extractSearchTerms(task.title);
        if (task.description != null) {
          _extractSearchTerms(task.description!);
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize search terms cache: $e');
    }
  }

  /// Extract search terms from text for autocomplete
  void _extractSearchTerms(String text) {
    final terms = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((term) => term.length > 2)
        .toSet();
    _searchTermsCache.addAll(terms);
  }

  /// Start periodic cache cleanup
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredCache();
    });
  }

  /// Remove expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _searchCache.removeWhere((key, entry) {
      return now.difference(entry.timestamp) > _cacheExpiry;
    });
  }

  /// Enhanced search with pagination and performance optimizations
  Future<SearchResults> searchTasksAdvanced({
    String? query,
    SearchFilters? filters,
    SearchSort sort = SearchSort.relevance,
    int page = 0,
    int pageSize = 20,
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Create cache key
    final cacheKey = _createCacheKey(query, filters, sort, page, pageSize);

    // Check cache first
    if (useCache && _searchCache.containsKey(cacheKey)) {
      final cachedEntry = _searchCache[cacheKey]!;
      if (DateTime.now().difference(cachedEntry.timestamp) < _cacheExpiry) {
        return cachedEntry.results;
      }
    }

    try {
      // Perform search
      final results = await _performAdvancedSearch(
        query: query,
        filters: filters,
        sort: sort,
        page: page,
        pageSize: pageSize,
      );

      stopwatch.stop();
      final finalResults = results.copyWith(
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );

      // Cache results
      if (useCache) {
        _cacheSearchResults(cacheKey, finalResults);
      }

      return finalResults;
    } catch (e) {
      debugPrint('Advanced search failed: $e');
      return SearchResults.empty();
    }
  }

  /// Core advanced search implementation
  Future<SearchResults> _performAdvancedSearch({
    String? query,
    SearchFilters? filters,
    SearchSort sort = SearchSort.relevance,
    int page = 0,
    int pageSize = 20,
  }) async {
    List<Task> allTasks;

    // Start with repository query
    if (query != null && query.trim().isNotEmpty) {
      allTasks = await _taskRepository.searchTasks(query);
    } else {
      allTasks = await _taskRepository.getAllTasks();
    }

    // Apply filters
    if (filters != null) {
      allTasks = _applyAdvancedFilters(allTasks, filters);
    }

    // Apply sorting
    _applySorting(allTasks, sort);

    // Calculate pagination
    final totalCount = allTasks.length;
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    // Get paginated results
    final paginatedTasks = startIndex < totalCount
        ? allTasks.sublist(startIndex, endIndex)
        : <Task>[];

    // Generate highlights if query provided
    final highlights = query != null && query.trim().isNotEmpty
        ? _generateHighlights(paginatedTasks, query)
        : <String, List<TextHighlight>>{};

    return SearchResults(
      tasks: paginatedTasks,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      hasMore: endIndex < totalCount,
      query: query,
      filters: filters,
      sort: sort,
      highlights: highlights,
      executionTimeMs: 0, // Will be set by caller
    );
  }

  /// Search tasks with comprehensive filtering options (legacy method)
  Future<List<Task>> searchTasks({
    String? query,
    List<String>? categoryIds,
    List<TaskPriority>? priorities,
    List<TaskSource>? sources,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
    bool? isOverdue,
    bool? isDueToday,
    bool? isDueTomorrow,
    bool? hasReminder,
    int? limit,
  }) async {
    // Start with all tasks
    var tasks = await _taskRepository.getAllTasks();

    // Apply text search filter
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(lowercaseQuery) ||
            (task.description?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    }

    // Apply category filter
    if (categoryIds != null && categoryIds.isNotEmpty) {
      tasks =
          tasks.where((task) => categoryIds.contains(task.categoryId)).toList();
    }

    // Apply priority filter
    if (priorities != null && priorities.isNotEmpty) {
      tasks =
          tasks.where((task) => priorities.contains(task.priority)).toList();
    }

    // Apply source filter
    if (sources != null && sources.isNotEmpty) {
      tasks = tasks.where((task) => sources.contains(task.source)).toList();
    }

    // Apply completion status filter
    if (isCompleted != null) {
      tasks = tasks.where((task) => task.isCompleted == isCompleted).toList();
    }

    // Apply date range filter
    if (startDate != null || endDate != null) {
      tasks = tasks.where((task) {
        if (task.dueDate == null) return false;

        if (startDate != null && task.dueDate!.isBefore(startDate)) {
          return false;
        }

        if (endDate != null && task.dueDate!.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();
    }

    // Apply overdue filter
    if (isOverdue == true) {
      tasks = tasks.where((task) => task.isOverdue).toList();
    }

    // Apply due today filter
    if (isDueToday == true) {
      tasks = tasks.where((task) => task.isDueToday).toList();
    }

    // Apply due tomorrow filter
    if (isDueTomorrow == true) {
      tasks = tasks.where((task) => task.isDueTomorrow).toList();
    }

    // Apply reminder filter
    if (hasReminder != null) {
      tasks = tasks.where((task) => task.hasReminder == hasReminder).toList();
    }

    // Sort by relevance (completed tasks last, then by priority, then by due date)
    tasks.sort((a, b) {
      // Completed tasks go to the bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Sort by priority (urgent first)
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index);
      }

      // Sort by due date (earlier dates first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // Finally sort by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });

    // Apply limit if specified
    if (limit != null && limit > 0) {
      tasks = tasks.take(limit).toList();
    }

    return tasks;
  }

  /// Get smart search suggestions based on query
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final suggestions = <SearchSuggestion>[];
    final lowercaseQuery = query.toLowerCase();

    // Get recent tasks for title suggestions
    final recentTasks = await _taskRepository.getAllTasks();
    recentTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Add title suggestions
    final titleSuggestions = recentTasks
        .where((task) => task.title.toLowerCase().contains(lowercaseQuery))
        .take(5)
        .map((task) => SearchSuggestion(
              type: SearchSuggestionType.title,
              text: task.title,
              task: task,
            ))
        .toList();
    suggestions.addAll(titleSuggestions);

    // Add category suggestions
    final categories = await _categoryRepository.getAllCategories();
    final categorySuggestions = categories
        .where(
            (category) => category.name.toLowerCase().contains(lowercaseQuery))
        .map((category) => SearchSuggestion(
              type: SearchSuggestionType.category,
              text: 'Category: ${category.name}',
              categoryId: category.id,
            ))
        .toList();
    suggestions.addAll(categorySuggestions);

    // Add predefined filters
    final predefinedFilters = [
      if ('overdue'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'Overdue tasks',
          filterType: TaskFilterType.overdue,
        ),
      if ('today'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'Due today',
          filterType: TaskFilterType.dueToday,
        ),
      if ('tomorrow'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'Due tomorrow',
          filterType: TaskFilterType.dueTomorrow,
        ),
      if ('completed'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'Completed tasks',
          filterType: TaskFilterType.completed,
        ),
      if ('pending'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'Pending tasks',
          filterType: TaskFilterType.pending,
        ),
      if ('high priority'.contains(lowercaseQuery) ||
          'urgent'.contains(lowercaseQuery))
        SearchSuggestion(
          type: SearchSuggestionType.filter,
          text: 'High priority tasks',
          filterType: TaskFilterType.highPriority,
        ),
    ];
    suggestions.addAll(predefinedFilters);

    return suggestions.take(10).toList();
  }

  /// Get quick filters for the search interface
  List<QuickFilter> getQuickFilters() {
    return [
      QuickFilter(
        label: 'All',
        icon: Icons.list,
        filterType: TaskFilterType.all,
      ),
      QuickFilter(
        label: 'Pending',
        icon: Icons.pending,
        filterType: TaskFilterType.pending,
      ),
      QuickFilter(
        label: 'Overdue',
        icon: Icons.schedule,
        filterType: TaskFilterType.overdue,
        color: Colors.red,
      ),
      QuickFilter(
        label: 'Today',
        icon: Icons.today,
        filterType: TaskFilterType.dueToday,
        color: Colors.orange,
      ),
      QuickFilter(
        label: 'Tomorrow',
        icon: Icons.event,
        filterType: TaskFilterType.dueTomorrow,
        color: Colors.blue,
      ),
      QuickFilter(
        label: 'Completed',
        icon: Icons.check_circle,
        filterType: TaskFilterType.completed,
        color: Colors.green,
      ),
      QuickFilter(
        label: 'High Priority',
        icon: Icons.priority_high,
        filterType: TaskFilterType.highPriority,
        color: Colors.red,
      ),
    ];
  }

  /// Apply a quick filter to get filtered tasks
  Future<List<Task>> applyQuickFilter(TaskFilterType filterType) async {
    switch (filterType) {
      case TaskFilterType.all:
        return await _taskRepository.getAllTasks();
      case TaskFilterType.pending:
        return await _taskRepository.getPendingTasks();
      case TaskFilterType.completed:
        return await _taskRepository.getCompletedTasks();
      case TaskFilterType.overdue:
        return await _taskRepository.getOverdueTasks();
      case TaskFilterType.dueToday:
        return await searchTasks(isDueToday: true);
      case TaskFilterType.dueTomorrow:
        return await searchTasks(isDueTomorrow: true);
      case TaskFilterType.highPriority:
        return await searchTasks(
          priorities: [TaskPriority.high, TaskPriority.urgent],
        );
    }
  }

  /// Get advanced search options for the filter UI
  SearchFilterOptions getAdvancedFilterOptions() {
    return SearchFilterOptions(
      priorities: TaskPriority.values.toList(),
      sources: TaskSource.values.toList(),
      sortOptions: [
        SortOption(
          label: 'Due Date',
          type: SortType.dueDate,
          icon: Icons.calendar_today,
        ),
        SortOption(
          label: 'Priority',
          type: SortType.priority,
          icon: Icons.priority_high,
        ),
        SortOption(
          label: 'Created Date',
          type: SortType.createdDate,
          icon: Icons.access_time,
        ),
        SortOption(
          label: 'Title',
          type: SortType.title,
          icon: Icons.sort_by_alpha,
        ),
      ],
    );
  }
}

/// Search suggestion model
class SearchSuggestion {
  final SearchSuggestionType type;
  final String text;
  final Task? task;
  final String? categoryId;
  final TaskFilterType? filterType;

  SearchSuggestion({
    required this.type,
    required this.text,
    this.task,
    this.categoryId,
    this.filterType,
  });
}

/// Types of search suggestions
enum SearchSuggestionType {
  title,
  category,
  filter,
}

/// Quick filter model
class QuickFilter {
  final String label;
  final IconData icon;
  final TaskFilterType filterType;
  final Color? color;

  QuickFilter({
    required this.label,
    required this.icon,
    required this.filterType,
    this.color,
  });
}

/// Task filter types for quick access
enum TaskFilterType {
  all,
  pending,
  completed,
  overdue,
  dueToday,
  dueTomorrow,
  highPriority,
}

/// Advanced search filter options
class SearchFilterOptions {
  final List<TaskPriority> priorities;
  final List<TaskSource> sources;
  final List<SortOption> sortOptions;

  SearchFilterOptions({
    required this.priorities,
    required this.sources,
    required this.sortOptions,
  });
}

/// Sort option model
class SortOption {
  final String label;
  final SortType type;
  final IconData icon;

  SortOption({
    required this.label,
    required this.type,
    required this.icon,
  });
}

/// Sort types
enum SortType {
  dueDate,
  priority,
  createdDate,
  title,
}

/// Enhanced search result types and helper methods
class SearchResults {
  final List<Task> tasks;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String? query;
  final SearchFilters? filters;
  final SearchSort? sort;
  final Map<String, List<TextHighlight>> highlights;
  final int executionTimeMs;

  const SearchResults({
    required this.tasks,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.query,
    this.filters,
    this.sort,
    this.highlights = const {},
    this.executionTimeMs = 0,
  });

  factory SearchResults.empty() {
    return const SearchResults(
      tasks: [],
      totalCount: 0,
      page: 0,
      pageSize: 20,
      hasMore: false,
    );
  }

  SearchResults copyWith({
    List<Task>? tasks,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasMore,
    String? query,
    SearchFilters? filters,
    SearchSort? sort,
    Map<String, List<TextHighlight>>? highlights,
    int? executionTimeMs,
  }) {
    return SearchResults(
      tasks: tasks ?? this.tasks,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
      highlights: highlights ?? this.highlights,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
    );
  }

  bool get isEmpty => tasks.isEmpty;
  bool get isNotEmpty => tasks.isNotEmpty;
  int get pageCount => totalCount > 0 ? ((totalCount - 1) ~/ pageSize) + 1 : 0;
}

/// Advanced search filters
class SearchFilters {
  final List<String> categoryIds;
  final TaskStatus? status;
  final List<TaskPriority> priorities;
  final List<TaskSource> sources;
  final DateTimeRange? dateRange;
  final bool? hasReminder;
  final bool? hasDueDate;

  const SearchFilters({
    this.categoryIds = const [],
    this.status,
    this.priorities = const [],
    this.sources = const [],
    this.dateRange,
    this.hasReminder,
    this.hasDueDate,
  });

  bool get isEmpty {
    return categoryIds.isEmpty &&
        status == null &&
        priorities.isEmpty &&
        sources.isEmpty &&
        dateRange == null &&
        hasReminder == null &&
        hasDueDate == null;
  }
}

/// Task status for advanced filtering
enum TaskStatus {
  completed,
  pending,
  overdue,
}

/// Search sorting options
enum SearchSort {
  relevance,
  dateCreated,
  dateUpdated,
  dueDate,
  priority,
  title,
  category,
}

/// Text highlight for search results
class TextHighlight {
  final String field;
  final int start;
  final int end;
  final String matchedText;

  const TextHighlight({
    required this.field,
    required this.start,
    required this.end,
    required this.matchedText,
  });
}

/// Search cache entry
class SearchCacheEntry {
  final SearchResults results;
  final DateTime timestamp;

  const SearchCacheEntry({
    required this.results,
    required this.timestamp,
  });
}

/// Date time range for filtering
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });
}

// Extension methods for SearchService
extension SearchServiceHelpers on SearchService {
  /// Apply advanced filters to task list
  List<Task> _applyAdvancedFilters(List<Task> tasks, SearchFilters filters) {
    return tasks.where((task) {
      // Category filter
      if (filters.categoryIds.isNotEmpty &&
          !filters.categoryIds.contains(task.categoryId)) {
        return false;
      }

      // Status filter
      if (filters.status != null) {
        switch (filters.status!) {
          case TaskStatus.completed:
            if (!task.isCompleted) return false;
            break;
          case TaskStatus.pending:
            if (task.isCompleted) return false;
            break;
          case TaskStatus.overdue:
            if (!task.isOverdue) return false;
            break;
        }
      }

      // Priority filter
      if (filters.priorities.isNotEmpty &&
          !filters.priorities.contains(task.priority)) {
        return false;
      }

      // Source filter
      if (filters.sources.isNotEmpty &&
          !filters.sources.contains(task.source)) {
        return false;
      }

      // Date range filter
      if (filters.dateRange != null && task.dueDate != null) {
        final taskDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (taskDate.isBefore(filters.dateRange!.start) ||
            taskDate.isAfter(filters.dateRange!.end)) {
          return false;
        }
      }

      // Has reminder filter
      if (filters.hasReminder != null &&
          task.hasReminder != filters.hasReminder!) {
        return false;
      }

      // Has due date filter
      if (filters.hasDueDate != null) {
        final hasDue = task.dueDate != null;
        if (hasDue != filters.hasDueDate!) return false;
      }

      return true;
    }).toList();
  }

  /// Apply sorting with multiple criteria
  void _applySorting(List<Task> tasks, SearchSort sort) {
    switch (sort) {
      case SearchSort.relevance:
        // Maintain current order for relevance
        break;
      case SearchSort.dateCreated:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSort.dateUpdated:
        tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SearchSort.dueDate:
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateCompare = a.dueDate!.compareTo(b.dueDate!);
          if (dateCompare != 0) return dateCompare;
          // Secondary sort by time if dates are equal
          if (a.dueTime == null && b.dueTime == null) return 0;
          if (a.dueTime == null) return 1;
          if (b.dueTime == null) return -1;
          final aMinutes = a.dueTime!.hour * 60 + a.dueTime!.minute;
          final bMinutes = b.dueTime!.hour * 60 + b.dueTime!.minute;
          return aMinutes.compareTo(bMinutes);
        });
        break;
      case SearchSort.priority:
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case SearchSort.title:
        tasks.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SearchSort.category:
        tasks.sort((a, b) => a.categoryId.compareTo(b.categoryId));
        break;
    }
  }

  /// Generate text highlights for search results
  Map<String, List<TextHighlight>> _generateHighlights(
      List<Task> tasks, String query) {
    final highlights = <String, List<TextHighlight>>{};
    final searchTerms =
        query.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();

    for (final task in tasks) {
      final taskHighlights = <TextHighlight>[];

      // Check title for highlights
      for (final term in searchTerms) {
        final titleLower = task.title.toLowerCase();
        int index = titleLower.indexOf(term);
        while (index != -1) {
          taskHighlights.add(TextHighlight(
            field: 'title',
            start: index,
            end: index + term.length,
            matchedText: task.title.substring(index, index + term.length),
          ));
          index = titleLower.indexOf(term, index + 1);
        }
      }

      // Check description for highlights
      if (task.description != null) {
        for (final term in searchTerms) {
          final descLower = task.description!.toLowerCase();
          int index = descLower.indexOf(term);
          while (index != -1) {
            taskHighlights.add(TextHighlight(
              field: 'description',
              start: index,
              end: index + term.length,
              matchedText:
                  task.description!.substring(index, index + term.length),
            ));
            index = descLower.indexOf(term, index + 1);
          }
        }
      }

      if (taskHighlights.isNotEmpty) {
        highlights[task.id] = taskHighlights;
      }
    }

    return highlights;
  }

  /// Create cache key for search results
  String _createCacheKey(String? query, SearchFilters? filters, SearchSort sort,
      int page, int pageSize) {
    final parts = <String>[
      query ?? '',
      filters?.categoryIds.join(',') ?? '',
      filters?.status?.name ?? '',
      filters?.priorities.map((p) => p.name).join(',') ?? '',
      filters?.sources.map((s) => s.name).join(',') ?? '',
      filters?.dateRange != null
          ? '${filters!.dateRange!.start.millisecondsSinceEpoch}-${filters.dateRange!.end.millisecondsSinceEpoch}'
          : '',
      filters?.hasReminder?.toString() ?? '',
      filters?.hasDueDate?.toString() ?? '',
      sort.name,
      page.toString(),
      pageSize.toString(),
    ];
    return parts.join('|');
  }

  /// Cache search results with size limit
  void _cacheSearchResults(String key, SearchResults results) {
    // Remove oldest entries if cache is full
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    _searchCache[key] = SearchCacheEntry(
      results: results,
      timestamp: DateTime.now(),
    );
  }

  /// Get enhanced autocomplete suggestions
  Future<List<SearchSuggestion>> getEnhancedSuggestions(String input) async {
    if (input.length < 2) return [];

    final inputLower = input.toLowerCase();
    final suggestions = <SearchSuggestion>[];

    // Add term-based suggestions from cache
    final matchingTerms = _searchTermsCache
        .where((term) => term.startsWith(inputLower))
        .take(5)
        .map((term) => SearchSuggestion(
              type: SearchSuggestionType.title,
              text: term,
            ));
    suggestions.addAll(matchingTerms);

    // Add category suggestions
    try {
      final categories = await _categoryRepository.getAllCategories();
      final categorySuggestions = categories
          .where((cat) => cat.name.toLowerCase().contains(inputLower))
          .map((cat) => SearchSuggestion(
                type: SearchSuggestionType.category,
                text: 'Category: ${cat.name}',
                categoryId: cat.id,
              ));
      suggestions.addAll(categorySuggestions);
    } catch (e) {
      debugPrint('Failed to get category suggestions: $e');
    }

    return suggestions.take(10).toList();
  }

  /// Clear cache and dispose resources
  void dispose() {
    _searchCache.clear();
    _searchTermsCache.clear();
    _cacheCleanupTimer?.cancel();
  }

  /// Get search performance analytics
  Map<String, dynamic> getSearchAnalytics() {
    return {
      'cacheSize': _searchCache.length,
      'termsCount': _searchTermsCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheExpiry': _cacheExpiry.inMinutes,
    };
  }
}
