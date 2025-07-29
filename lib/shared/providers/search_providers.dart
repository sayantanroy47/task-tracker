import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/search_service.dart';
import '../../shared/models/models.dart';
import 'app_providers.dart';

/// Search-related providers for advanced search functionality
/// Provides reactive search state management with performance optimizations

/// Current search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search filters provider with complex state management
final searchFiltersProvider = StateNotifierProvider<SearchFiltersNotifier, SearchFilters>((ref) {
  return SearchFiltersNotifier();
});

/// Search results provider with pagination
final searchResultsProvider = FutureProvider.family<SearchResults, SearchParams>((ref, params) async {
  final searchService = ref.read(searchServiceProvider);
  
  return await searchService.searchTasksAdvanced(
    query: params.query.isEmpty ? null : params.query,
    filters: params.filters.isEmpty ? null : params.filters,
    sort: params.sort,
    page: params.page,
    pageSize: params.pageSize,
    useCache: params.useCache,
  );
});

/// Search suggestions provider with debouncing
final searchSuggestionsProvider = FutureProvider.family<List<SearchSuggestion>, String>((ref, query) async {
  if (query.length < 2) {
    // Return quick filters for empty query
    return _getQuickFilterSuggestions();
  }
  
  final searchService = ref.read(searchServiceProvider);
  return await searchService.getEnhancedSuggestions(query);
});

/// Combined search state provider
final searchStateProvider = Provider<SearchState>((ref) {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final searchParams = SearchParams(
    query: query,
    filters: filters,
    sort: SearchSort.relevance,
  );
  
  final searchResults = ref.watch(searchResultsProvider(searchParams));
  
  return SearchState(
    query: query,
    filters: filters,
    isLoading: searchResults.isLoading,
    results: searchResults.valueOrNull,
    error: searchResults.error,
    hasActiveFilters: !filters.isEmpty,
  );
});

/// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final taskRepository = ref.read(taskRepositoryProvider);
  final categoryRepository = ref.read(categoryRepositoryProvider);
  
  return SearchService(
    taskRepository: taskRepository,
    categoryRepository: categoryRepository,
  );
});

/// Task search results provider (filtered by current search state)
final filteredTasksProvider = FutureProvider<List<Task>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  
  if (searchState.query.isEmpty && searchState.filters.isEmpty) {
    // Return all tasks if no search/filters
    final taskRepository = ref.read(taskRepositoryProvider);
    return await taskRepository.getAllTasks();
  }
  
  final results = searchState.results;
  return results?.tasks ?? [];
});

/// Search analytics provider
final searchAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final searchService = ref.read(searchServiceProvider);
  return searchService.getSearchAnalytics();
});

/// Search filters state notifier
class SearchFiltersNotifier extends StateNotifier<SearchFilters> {
  SearchFiltersNotifier() : super(const SearchFilters());

  /// Set task status filter
  void setStatus(TaskStatus? status) {
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: status,
      priorities: state.priorities,
      sources: state.sources,
      dateRange: state.dateRange,
      hasReminder: state.hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Toggle priority filter
  void togglePriority(TaskPriority priority) {
    final priorities = state.priorities.toList();
    if (priorities.contains(priority)) {
      priorities.remove(priority);
    } else {
      priorities.add(priority);
    }
    
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: state.status,
      priorities: priorities,
      sources: state.sources,
      dateRange: state.dateRange,
      hasReminder: state.hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Toggle source filter
  void toggleSource(TaskSource source) {
    final sources = state.sources.toList();
    if (sources.contains(source)) {
      sources.remove(source);
    } else {
      sources.add(source);
    }
    
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: state.status,
      priorities: state.priorities,
      sources: sources,
      dateRange: state.dateRange,
      hasReminder: state.hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Toggle category filter
  void toggleCategory(String categoryId) {
    final categoryIds = state.categoryIds.toList();
    if (categoryIds.contains(categoryId)) {
      categoryIds.remove(categoryId);
    } else {
      categoryIds.add(categoryId);
    }
    
    state = SearchFilters(
      categoryIds: categoryIds,
      status: state.status,
      priorities: state.priorities,
      sources: state.sources,
      dateRange: state.dateRange,
      hasReminder: state.hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Set date range filter
  void setDateRange(DateTimeRange? range) {
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: state.status,
      priorities: state.priorities,
      sources: state.sources,
      dateRange: range,
      hasReminder: state.hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Set has reminder filter
  void setHasReminder(bool? hasReminder) {
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: state.status,
      priorities: state.priorities,
      sources: state.sources,
      dateRange: state.dateRange,
      hasReminder: hasReminder,
      hasDueDate: state.hasDueDate,
    );
  }

  /// Set has due date filter
  void setHasDueDate(bool? hasDueDate) {
    state = SearchFilters(
      categoryIds: state.categoryIds,
      status: state.status,
      priorities: state.priorities,
      sources: state.sources,
      dateRange: state.dateRange,
      hasReminder: state.hasReminder,
      hasDueDate: hasDueDate,
    );
  }

  /// Apply quick filter
  void setQuickFilter(String filterType) {
    switch (filterType) {
      case 'today':
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        setDateRange(DateTimeRange(start: todayStart, end: todayEnd));
        break;
        
      case 'overdue':
        setStatus(TaskStatus.overdue);
        break;
        
      case 'high_priority':
        state = SearchFilters(
          categoryIds: state.categoryIds,
          status: state.status,
          priorities: [TaskPriority.high, TaskPriority.urgent],
          sources: state.sources,
          dateRange: state.dateRange,
          hasReminder: state.hasReminder,
          hasDueDate: state.hasDueDate,
        );
        break;
        
      case 'completed':
        setStatus(TaskStatus.completed);
        break;
        
      case 'pending':
        setStatus(TaskStatus.pending);
        break;
    }
  }

  /// Clear all filters
  void clearFilters() {
    state = const SearchFilters();
  }

  /// Set complete filter state
  void setFilters(SearchFilters filters) {
    state = filters;
  }
}

/// Search parameters model
class SearchParams {
  final String query;
  final SearchFilters filters;
  final SearchSort sort;
  final int page;
  final int pageSize;
  final bool useCache;

  const SearchParams({
    required this.query,
    required this.filters,
    required this.sort,
    this.page = 0,
    this.pageSize = 20,
    this.useCache = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchParams &&
        other.query == query &&
        other.filters == filters &&
        other.sort == sort &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.useCache == useCache;
  }

  @override
  int get hashCode {
    return Object.hash(query, filters, sort, page, pageSize, useCache);
  }
}

/// Combined search state model
class SearchState {
  final String query;
  final SearchFilters filters;
  final bool isLoading;
  final SearchResults? results;
  final Object? error;
  final bool hasActiveFilters;

  const SearchState({
    required this.query,
    required this.filters,
    required this.isLoading,
    this.results,
    this.error,
    required this.hasActiveFilters,
  });

  bool get hasResults => results != null && results!.isNotEmpty;
  bool get hasError => error != null;
  int get totalResults => results?.totalCount ?? 0;
}

/// Helper function to get quick filter suggestions
List<SearchSuggestion> _getQuickFilterSuggestions() {
  return [
    const SearchSuggestion(
      type: SearchSuggestionType.filter,
      text: 'Due today',
    ),
    const SearchSuggestion(
      type: SearchSuggestionType.filter,
      text: 'Overdue tasks',
    ),
    const SearchSuggestion(
      type: SearchSuggestionType.filter,
      text: 'High priority',
    ),
    const SearchSuggestion(
      type: SearchSuggestionType.filter,
      text: 'Completed tasks',
    ),
    const SearchSuggestion(
      type: SearchSuggestionType.filter,
      text: 'Pending tasks',
    ),
  ];
}