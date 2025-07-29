import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/search_service.dart';
import '../providers/search_providers.dart';
import '../../core/constants/constants.dart';

/// Advanced search bar widget with autocomplete and smart suggestions
/// Optimized for performance with debounced search and caching
class SearchBarWidget extends ConsumerStatefulWidget {
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function(SearchSuggestion)? onSuggestionSelected;
  final bool autofocus;
  final bool showFilters;

  const SearchBarWidget({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onSuggestionSelected,
    this.autofocus = false,
    this.showFilters = true,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showSuggestions();
      _animationController.forward();
    } else {
      _hideSuggestions();
      _animationController.reverse();
    }
  }

  void _onTextChanged(String value) {
    widget.onChanged?.call(value);
    
    // Update search query in provider
    ref.read(searchQueryProvider.notifier).state = value;
    
    if (value.isNotEmpty) {
      _showSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  void _showSuggestions() {
    _removeOverlay();
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12),
              child: _SearchSuggestionsOverlay(
                query: _controller.text,
                onSuggestionSelected: (suggestion) {
                  _controller.text = suggestion.text;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: suggestion.text.length),
                  );
                  widget.onSuggestionSelected?.call(suggestion);
                  _hideSuggestions();
                  _focusNode.unfocus();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchStateProvider);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.5),
            width: _focusNode.hasFocus ? 2 : 1,
          ),
          boxShadow: _focusNode.hasFocus ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Search icon
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                Icons.search,
                color: _focusNode.hasFocus 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            
            // Search input field
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Search tasks...',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: _onTextChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            
            // Loading indicator
            if (searchState.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            
            // Clear button
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  _onTextChanged('');
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            
            // Filter button
            if (widget.showFilters)
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 18,
                  color: searchState.hasActiveFilters 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _showFilterBottomSheet(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilterBottomSheet(),
    );
  }
}

/// Search suggestions overlay widget
class _SearchSuggestionsOverlay extends ConsumerWidget {
  final String query;
  final Function(SearchSuggestion) onSuggestionSelected;

  const _SearchSuggestionsOverlay({
    required this.query,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suggestions = ref.watch(searchSuggestionsProvider(query));

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: suggestions.when(
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick filters section
              if (query.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Filters',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _QuickFiltersRow(),
                const Divider(height: 1),
              ],
              
              // Suggestions list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return _SuggestionItem(
                      suggestion: suggestion,
                      query: query,
                      onSelected: onSuggestionSelected,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Quick filters row widget
class _QuickFiltersRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _QuickFilterChip(
            label: 'Today',
            icon: Icons.today,
            onTap: () => ref.read(searchFiltersProvider.notifier).setQuickFilter('today'),
          ),
          _QuickFilterChip(
            label: 'Overdue',
            icon: Icons.schedule,
            color: theme.colorScheme.error,
            onTap: () => ref.read(searchFiltersProvider.notifier).setQuickFilter('overdue'),
          ),
          _QuickFilterChip(
            label: 'High Priority',
            icon: Icons.priority_high,
            onTap: () => ref.read(searchFiltersProvider.notifier).setQuickFilter('high_priority'),
          ),
        ],
      ),
    );
  }
}

/// Quick filter chip widget
class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual suggestion item widget
class _SuggestionItem extends StatelessWidget {
  final SearchSuggestion suggestion;
  final String query;
  final Function(SearchSuggestion) onSelected;

  const _SuggestionItem({
    required this.suggestion,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: _getSuggestionIcon(theme),
      title: _buildHighlightedText(suggestion.text, query, theme),
      onTap: () => onSelected(suggestion),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _getSuggestionIcon(ThemeData theme) {
    switch (suggestion.type) {
      case SearchSuggestionType.title:
        return Icon(Icons.task_alt, size: 18, color: theme.colorScheme.onSurfaceVariant);
      case SearchSuggestionType.category:
        return Icon(Icons.category, size: 18, color: theme.colorScheme.primary);
      case SearchSuggestionType.filter:
        return Icon(Icons.filter_list, size: 18, color: theme.colorScheme.secondary);
    }
  }

  Widget _buildHighlightedText(String text, String query, ThemeData theme) {
    if (query.isEmpty) {
      return Text(text, style: theme.textTheme.bodyMedium);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: theme.textTheme.bodyMedium);
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

/// Search filter bottom sheet
class SearchFilterBottomSheet extends ConsumerStatefulWidget {
  const SearchFilterBottomSheet({super.key});

  @override
  ConsumerState<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends ConsumerState<SearchFilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(searchFiltersProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Tasks',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(searchFiltersProvider.notifier).clearFilters();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          
          // Filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  _FilterSection(
                    title: 'Status',
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: filters.status == null,
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .setStatus(null),
                        ),
                        _FilterChip(
                          label: 'Pending',
                          isSelected: filters.status == TaskStatus.pending,
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .setStatus(TaskStatus.pending),
                        ),
                        _FilterChip(
                          label: 'Completed',
                          isSelected: filters.status == TaskStatus.completed,
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .setStatus(TaskStatus.completed),
                        ),
                        _FilterChip(
                          label: 'Overdue',
                          isSelected: filters.status == TaskStatus.overdue,
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .setStatus(TaskStatus.overdue),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Priority filter
                  _FilterSection(
                    title: 'Priority',
                    child: Wrap(
                      spacing: 8,
                      children: TaskPriority.values.map((priority) {
                        return _FilterChip(
                          label: priority.displayName,
                          isSelected: filters.priorities.contains(priority),
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .togglePriority(priority),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Source filter
                  _FilterSection(
                    title: 'Source',
                    child: Wrap(
                      spacing: 8,
                      children: TaskSource.values.map((source) {
                        return _FilterChip(
                          label: source.name.toUpperCase(),
                          isSelected: filters.sources.contains(source),
                          onSelected: (selected) => ref.read(searchFiltersProvider.notifier)
                              .toggleSource(source),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date range filter
                  _FilterSection(
                    title: 'Due Date',
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Has Due Date'),
                          value: filters.hasDueDate ?? false,
                          onChanged: (value) => ref.read(searchFiltersProvider.notifier)
                              .setHasDueDate(value ? true : null),
                          contentPadding: EdgeInsets.zero,
                        ),
                        // Add date range picker here if needed
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter section widget
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.outline.withOpacity(0.5),
      ),
    );
  }
}