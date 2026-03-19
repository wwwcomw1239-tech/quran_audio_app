import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../models/surah_model.dart';
import '../providers/quran_provider.dart';
import '../services/download_service.dart';

/// Card widget for displaying a Surah in the list
class SurahCard extends StatefulWidget {
  /// The surah to display
  final SurahModel surah;

  /// Callback when surah is tapped
  final VoidCallback? onTap;

  /// Callback when play button is tapped
  final VoidCallback? onPlayTap;

  /// Callback when download button is tapped
  final VoidCallback? onDownloadTap;

  /// Callback when favorite button is tapped
  final VoidCallback? onFavoriteTap;

  /// Whether to show download progress
  final bool showDownloadProgress;

  const SurahCard({
    super.key,
    required this.surah,
    this.onTap,
    this.onPlayTap,
    this.onDownloadTap,
    this.onFavoriteTap,
    this.showDownloadProgress = true,
  });

  @override
  State<SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<SurahCard>
    with SingleTickerProviderStateMixin {
  /// Animation controller for download button
  AnimationController? _downloadAnimationController;

  /// Download service instance
  final DownloadService _downloadService = DownloadService();

  @override
  void initState() {
    super.initState();
    _downloadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _downloadAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    // Check if this surah is currently playing
    final isPlaying = provider.isSurahPlaying(widget.surah.id);

    // Check if currently downloading
    final downloadTask = _downloadService.getDownloadTask(widget.surah.id);
    final isDownloading =
        downloadTask != null && downloadTask.status == DownloadStatus.downloading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: isPlaying
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Surah number badge
                  _buildSurahNumberBadge(colorScheme),

                  const SizedBox(width: 16),

                  // Surah info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arabic name
                        Text(
                          widget.surah.nameArabic,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPlaying
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // English name and type
                        Row(
                          children: [
                            Text(
                              widget.surah.nameEnglish,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(colorScheme),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Verses count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.surah.versesCount}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'آية',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Download progress (if downloading)
              if (widget.showDownloadProgress && isDownloading) ...[
                const SizedBox(height: 12),
                _buildDownloadProgress(downloadTask, colorScheme),
              ],

              // Action buttons row
              const SizedBox(height: 12),
              _buildActionButtons(colorScheme, provider),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  /// Build surah number badge
  Widget _buildSurahNumberBadge(ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _SurahNumberPainter(
                color: colorScheme.onPrimary.withOpacity(0.1),
              ),
            ),
          ),
          // Number
          Text(
            widget.surah.id.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build type chip (مكية / مدنية)
  Widget _buildTypeChip(ColorScheme colorScheme) {
    final isMakki = widget.surah.type == 'مكية';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMakki
            ? colorScheme.secondaryContainer.withOpacity(0.5)
            : colorScheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.surah.type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isMakki
              ? colorScheme.onSecondaryContainer
              : colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }

  /// Build download progress bar
  Widget _buildDownloadProgress(
      DownloadTask downloadTask, ColorScheme colorScheme) {
    return StreamBuilder<double>(
      stream: downloadTask.progressStream,
      initialData: downloadTask.progress,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              progressColor: colorScheme.primary,
              barRadius: const Radius.circular(8),
              lineHeight: 6,
              padding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }

  /// Build action buttons row
  Widget _buildActionButtons(ColorScheme colorScheme, QuranProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Favorite button
        _buildIconButton(
          icon: widget.surah.isFavorite
              ? Icons.favorite
              : Icons.favorite_border_outlined,
          color: widget.surah.isFavorite
              ? Colors.red
              : colorScheme.onSurfaceVariant,
          onPressed: widget.onFavoriteTap,
          tooltip: widget.surah.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
        ),

        const SizedBox(width: 8),

        // Download button
        _buildDownloadButton(colorScheme),

        const SizedBox(width: 8),

        // Play button
        _buildPlayButton(colorScheme, provider),
      ],
    );
  }

  /// Build download button with different states
  Widget _buildDownloadButton(ColorScheme colorScheme) {
    final downloadTask = _downloadService.getDownloadTask(widget.surah.id);
    final isDownloading = downloadTask != null &&
        downloadTask.status == DownloadStatus.downloading;

    if (widget.surah.isDownloaded) {
      // Downloaded - show checkmark
      return _buildIconButton(
        icon: Icons.download_done,
        color: colorScheme.primary,
        onPressed: null,
        tooltip: 'تم التحميل',
      );
    } else if (isDownloading) {
      // Downloading - show cancel
      return _buildIconButton(
        icon: Icons.cancel_outlined,
        color: colorScheme.error,
        onPressed: () {
          _downloadService.cancelDownload(widget.surah.id);
          setState(() {});
        },
        tooltip: 'إلغاء التحميل',
      );
    } else {
      // Not downloaded - show download
      return _buildIconButton(
        icon: Icons.download_outlined,
        color: colorScheme.onSurfaceVariant,
        onPressed: widget.onDownloadTap,
        tooltip: 'تحميل',
      );
    }
  }

  /// Build play button
  Widget _buildPlayButton(ColorScheme colorScheme, QuranProvider provider) {
    final isPlaying = provider.isSurahPlaying(widget.surah.id);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPlayTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Build icon button with consistent styling
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: onPressed == null ? color : color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for decorative pattern on surah number badge
class _SurahNumberPainter extends CustomPainter {
  final Color color;

  _SurahNumberPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw decorative lines
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.3, 0);

    path.moveTo(size.width * 0.7, size.height);
    path.lineTo(size.width, size.height * 0.7);

    canvas.drawPath(path, paint);

    // Draw small circles
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      3,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact version of SurahCard for smaller displays
class SurahCardCompact extends StatelessWidget {
  final SurahModel surah;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final bool isPlaying;

  const SurahCardCompact({
    super.key,
    required this.surah,
    this.onTap,
    this.onPlayTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          surah.id.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        surah.nameArabic,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${surah.nameEnglish} • ${surah.versesCount} آية',
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: colorScheme.primary,
        ),
        onPressed: onPlayTap,
      ),
    );
  }
}
