import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/quran_provider.dart';

/// Filter chips widget for filtering surahs by type
class FilterChipsWidget extends StatelessWidget {
  /// Callback when filter is changed
  final ValueChanged<FilterType>? onFilterChanged;

  /// Whether to show the label above the chips
  final bool showLabel;

  /// Whether to use horizontal scroll or wrap
  final bool useScroll;

  const FilterChipsWidget({
    super.key,
    this.onFilterChanged,
    this.showLabel = true,
    this.useScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();
    final currentFilter = provider.currentFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (showLabel) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'تصفية السور',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Filter chips
        useScroll
            ? _buildHorizontalScroll(context, currentFilter, colorScheme)
            : _buildWrapLayout(context, currentFilter, colorScheme),
      ],
    );
  }

  /// Build horizontal scroll view for filter chips
  Widget _buildHorizontalScroll(
    BuildContext context,
    FilterType currentFilter,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'الكل',
            icon: Icons.list,
            filterType: FilterType.all,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 114,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'المكية',
            icon: Icons.mosque_outlined,
            filterType: FilterType.makki,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 86,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'المدنية',
            icon: Icons.location_city_outlined,
            filterType: FilterType.madani,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 28,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'المفضلة',
            icon: Icons.favorite_outline,
            filterType: FilterType.favorites,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: context.read<QuranProvider>().favoriteCount,
          ),
        ],
      ),
    );
  }

  /// Build wrap layout for filter chips
  Widget _buildWrapLayout(
    BuildContext context,
    FilterType currentFilter,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildChip(
            context: context,
            label: 'الكل',
            icon: Icons.list,
            filterType: FilterType.all,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 114,
          ),
          _buildChip(
            context: context,
            label: 'المكية',
            icon: Icons.mosque_outlined,
            filterType: FilterType.makki,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 86,
          ),
          _buildChip(
            context: context,
            label: 'المدنية',
            icon: Icons.location_city_outlined,
            filterType: FilterType.madani,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: 28,
          ),
          _buildChip(
            context: context,
            label: 'المفضلة',
            icon: Icons.favorite_outline,
            filterType: FilterType.favorites,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            count: context.read<QuranProvider>().favoriteCount,
          ),
        ],
      ),
    );
  }

  /// Build individual filter chip
  Widget _buildChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required FilterType filterType,
    required FilterType currentFilter,
    required ColorScheme colorScheme,
    required int count,
  }) {
    final isSelected = currentFilter == filterType;
    final provider = context.read<QuranProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onPrimary.withOpacity(0.2)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          provider.setFilter(filterType);
          onFilterChanged?.call(filterType);
        },
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        checkmarkColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }
}

/// Extended filter chips with additional options
class FilterChipsExtended extends StatelessWidget {
  final ValueChanged<FilterType>? onFilterChanged;

  const FilterChipsExtended({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();
    final currentFilter = provider.currentFilter;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تصفية السور',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (currentFilter != FilterType.all)
                TextButton.icon(
                  onPressed: () {
                    provider.setFilter(FilterType.all);
                    onFilterChanged?.call(FilterType.all);
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('إعادة تعيين'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Main filters
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildExtendedChip(
                context: context,
                label: 'جميع السور',
                icon: Icons.list,
                filterType: FilterType.all,
                currentFilter: currentFilter,
                colorScheme: colorScheme,
                count: 114,
                description: 'عرض كل السور',
              ),
              _buildExtendedChip(
                context: context,
                label: 'السور المكية',
                icon: Icons.mosque,
                filterType: FilterType.makki,
                currentFilter: currentFilter,
                colorScheme: colorScheme,
                count: 86,
                description: 'السور النازلة في مكة',
              ),
              _buildExtendedChip(
                context: context,
                label: 'السور المدنية',
                icon: Icons.location_city,
                filterType: FilterType.madani,
                currentFilter: currentFilter,
                colorScheme: colorScheme,
                count: 28,
                description: 'السور النازلة في المدينة',
              ),
              _buildExtendedChip(
                context: context,
                label: 'المفضلة',
                icon: Icons.favorite,
                filterType: FilterType.favorites,
                currentFilter: currentFilter,
                colorScheme: colorScheme,
                count: provider.favoriteCount,
                description: 'السور المضافة للمفضلة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required FilterType filterType,
    required FilterType currentFilter,
    required ColorScheme colorScheme,
    required int count,
    required String description,
  }) {
    final isSelected = currentFilter == filterType;
    final provider = context.read<QuranProvider>();

    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count سورة',
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? colorScheme.onPrimary.withOpacity(0.8)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        provider.setFilter(filterType);
        onFilterChanged?.call(filterType);
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Segmented filter control for compact spaces
class FilterSegmentedControl extends StatelessWidget {
  final ValueChanged<FilterType>? onFilterChanged;

  const FilterSegmentedControl({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();
    final currentFilter = provider.currentFilter;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegment(
            context: context,
            label: 'الكل',
            icon: Icons.apps,
            filterType: FilterType.all,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            isFirst: true,
          ),
          _buildDivider(colorScheme),
          _buildSegment(
            context: context,
            label: 'مكية',
            icon: Icons.mosque_outlined,
            filterType: FilterType.makki,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildSegment(
            context: context,
            label: 'مدنية',
            icon: Icons.location_city_outlined,
            filterType: FilterType.madani,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildSegment(
            context: context,
            label: 'مفضلة',
            icon: Icons.favorite_outline,
            filterType: FilterType.favorites,
            currentFilter: currentFilter,
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String label,
    required IconData icon,
    required FilterType filterType,
    required FilterType currentFilter,
    required ColorScheme colorScheme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = currentFilter == filterType;
    final provider = context.read<QuranProvider>();

    return Expanded(
      child: GestureDetector(
        onTap: () {
          provider.setFilter(filterType);
          onFilterChanged?.call(filterType);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(16) : Radius.zero,
              right: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 32,
      width: 1,
      color: colorScheme.outlineVariant,
    );
  }
}
