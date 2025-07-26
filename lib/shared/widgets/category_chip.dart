import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../models/models.dart';

/// Category chip component for task categorization
/// Optimized for one-handed use with clear visual feedback
class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final ValueChanged<Category>? onSelected;
  final bool showLabel;
  final bool isCompact;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onSelected,
    this.showLabel = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Color logic for accessibility and clarity
    final backgroundColor = isSelected 
        ? category.color
        : category.color.withOpacity(0.1);
    
    final foregroundColor = isSelected
        ? _getContrastingTextColor(category.color)
        : category.color;
    
    return GestureDetector(
      onTap: onSelected != null ? () => onSelected!(category) : null,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
          vertical: isCompact ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: isSelected 
              ? null 
              : Border.all(
                  color: category.color.withOpacity(0.3),
                  width: 1,
                ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: category.color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon
            Icon(
              category.iconData,
              size: isCompact ? 16 : 20,
              color: foregroundColor,
            ),
            
            // Category label (if showing labels)
            if (showLabel) ...[
              SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
              Text(
                category.name,
                style: (isCompact 
                    ? AppTextStyles.labelSmall 
                    : AppTextStyles.labelMedium
                ).copyWith(
                  color: foregroundColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Get contrasting text color for accessibility
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Horizontal scrollable list of category chips
class CategoryChipList extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category>? onCategorySelected;
  final bool showLabels;
  final bool isCompact;
  final EdgeInsets? padding;

  const CategoryChipList({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
    this.showLabels = true,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 36 : 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            category: category,
            isSelected: selectedCategory?.id == category.id,
            onSelected: onCategorySelected,
            showLabel: showLabels,
            isCompact: isCompact,
          );
        },
      ),
    );
  }
}

/// Wrapped layout of category chips
class CategoryChipWrap extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category>? onCategorySelected;
  final bool showLabels;
  final bool isCompact;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;

  const CategoryChipWrap({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
    this.showLabels = true,
    this.isCompact = false,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.sm,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: categories.map((category) {
          return CategoryChip(
            category: category,
            isSelected: selectedCategory?.id == category.id,
            onSelected: onCategorySelected,
            showLabel: showLabels,
            isCompact: isCompact,
          );
        }).toList(),
      ),
    );
  }
}

/// Single category display widget (non-interactive)
class CategoryDisplay extends StatelessWidget {
  final Category category;
  final bool showIcon;
  final bool showLabel;
  final bool isCompact;
  final Color? textColor;

  const CategoryDisplay({
    super.key,
    required this.category,
    this.showIcon = true,
    this.showLabel = true,
    this.isCompact = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? category.color;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            category.iconData,
            size: isCompact ? 14 : 16,
            color: color,
          ),
          if (showLabel) SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
        ],
        
        if (showLabel)
          Text(
            category.name,
            style: (isCompact 
                ? AppTextStyles.labelSmall 
                : AppTextStyles.labelMedium
            ).copyWith(color: color),
          ),
      ],
    );
  }
}