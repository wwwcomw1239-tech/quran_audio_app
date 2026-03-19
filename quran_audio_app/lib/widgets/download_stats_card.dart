import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../providers/quran_provider.dart';
import '../services/download_service.dart';

/// Card widget for displaying download statistics
class DownloadStatsCard extends StatefulWidget {
  /// Callback when download all button is tapped
  final VoidCallback? onDownloadAll;

  /// Callback when clear all button is tapped
  final VoidCallback? onClearAll;

  /// Whether to show download all button
  final bool showDownloadAllButton;

  /// Whether to show clear all button
  final bool showClearAllButton;

  /// Card style variant
  final DownloadStatsStyle style;

  const DownloadStatsCard({
    super.key,
    this.onDownloadAll,
    this.onClearAll,
    this.showDownloadAllButton = true,
    this.showClearAllButton = true,
    this.style = DownloadStatsStyle.compact,
  });

  @override
  State<DownloadStatsCard> createState() => _DownloadStatsCardState();
}

class _DownloadStatsCardState extends State<DownloadStatsCard> {
  /// Download service instance
  final DownloadService _downloadService = DownloadService();

  /// Total downloaded size
  int _totalSize = 0;

  /// Number of downloaded surahs
  int _downloadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Load download statistics
  Future<void> _loadStats() async {
    final size = await _downloadService.getTotalDownloadedSize();
    final ids = await _downloadService.getDownloadedSurahIds();
    if (mounted) {
      setState(() {
        _totalSize = size;
        _downloadedCount = ids.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    // Use provider count if available
    final downloadedCount = provider.downloadedCount > 0 
        ? provider.downloadedCount 
        : _downloadedCount;

    const totalSurahs = 114;
    final progress = downloadedCount / totalSurahs;

    return widget.style == DownloadStatsStyle.compact
        ? _buildCompactCard(theme, colorScheme, downloadedCount, totalSurahs, progress)
        : _buildExpandedCard(theme, colorScheme, downloadedCount, totalSurahs, progress);
  }

  /// Build compact style card
  Widget _buildCompactCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int downloadedCount,
    int totalSurahs,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.download_done,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'السور المحملة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$downloadedCount / $totalSurahs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          LinearPercentIndicator(
            percent: progress.clamp(0.0, 1.0),
            backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.1),
            progressColor: colorScheme.primary,
            barRadius: const Radius.circular(8),
            lineHeight: 8,
            padding: EdgeInsets.zero,
          ),

          const SizedBox(height: 12),

          // Size info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحجم الكلي: ${_downloadService.formatFileSize(_totalSize)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),

          // Action buttons
          if (widget.showDownloadAllButton || widget.showClearAllButton) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.showClearAllButton && downloadedCount > 0)
                  TextButton.icon(
                    onPressed: () => _showClearAllDialog(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                if (widget.showDownloadAllButton && downloadedCount < totalSurahs)
                  FilledButton.icon(
                    onPressed: widget.onDownloadAll,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('تحميل الكل'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  /// Build expanded style card
  Widget _buildExpandedCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int downloadedCount,
    int totalSurahs,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            'إحصائيات التحميل',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Circular progress indicator
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 12,
            percent: progress.clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'مكتمل',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            progressColor: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                theme,
                colorScheme,
                icon: Icons.audiotrack,
                label: 'سور محملة',
                value: downloadedCount.toString(),
              ),
              _buildDivider(colorScheme),
              _buildStatItem(
                theme,
                colorScheme,
                icon: Icons.cloud_done,
                label: 'سور متبقية',
                value: (totalSurahs - downloadedCount).toString(),
              ),
              _buildDivider(colorScheme),
              _buildStatItem(
                theme,
                colorScheme,
                icon: Icons.storage,
                label: 'الحجم',
                value: _downloadService.formatFileSize(_totalSize),
              ),
            ],
          ),

          // Action buttons
          if (widget.showDownloadAllButton || widget.showClearAllButton) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.showClearAllButton && downloadedCount > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showClearAllDialog(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('حذف الكل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (widget.showClearAllButton && 
                    widget.showDownloadAllButton && 
                    downloadedCount > 0 &&
                    downloadedCount < totalSurahs)
                  const SizedBox(width: 12),
                if (widget.showDownloadAllButton && downloadedCount < totalSurahs)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onDownloadAll,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('تحميل الكل'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  /// Build stat item
  Widget _buildStatItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build vertical divider
  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 60,
      width: 1,
      color: colorScheme.outlineVariant,
    );
  }

  /// Show clear all confirmation dialog
  void _showClearAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف جميع التحميلات'),
          content: Text(
            'هل أنت متأكد من حذف جميع السور المحملة؟\n'
            'الحجم المحذوف: ${_downloadService.formatFileSize(_totalSize)}',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onClearAll?.call();
                _loadStats();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}

/// Download stats card style enum
enum DownloadStatsStyle {
  /// Compact horizontal card
  compact,
  /// Expanded vertical card with circular progress
  expanded,
}

/// Mini download stats indicator for app bars
class DownloadStatsIndicator extends StatelessWidget {
  const DownloadStatsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final downloadedCount = provider.downloadedCount;
    const totalSurahs = 114;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: downloadedCount > 0
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            downloadedCount > 0 ? Icons.download_done : Icons.download_outlined,
            size: 16,
            color: downloadedCount > 0
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$downloadedCount/$totalSurahs',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: downloadedCount > 0
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Download stats tile for settings or lists
class DownloadStatsTile extends StatelessWidget {
  /// Callback when tile is tapped
  final VoidCallback? onTap;

  const DownloadStatsTile({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final downloadedCount = provider.downloadedCount;
    const totalSurahs = 114;
    final progress = downloadedCount / totalSurahs;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.download_done,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: const Text('السور المحملة'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearPercentIndicator(
            percent: progress.clamp(0.0, 1.0),
            backgroundColor: colorScheme.surfaceContainerHighest,
            progressColor: colorScheme.primary,
            barRadius: const Radius.circular(4),
            lineHeight: 4,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          Text(
            '$downloadedCount من $totalSurahs سورة',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Text(
        '${(progress * 100).toStringAsFixed(0)}%',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
