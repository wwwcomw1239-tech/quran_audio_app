import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../models/surah_model.dart';
import '../providers/quran_provider.dart';

/// Audio player bar widget for bottom of screen
class AudioPlayerBar extends StatefulWidget {
  /// Callback when play/pause is tapped
  final VoidCallback? onPlayPause;

  /// Callback when next is tapped
  final VoidCallback? onNext;

  /// Callback when previous is tapped
  final VoidCallback? onPrevious;

  /// Callback when seek is performed
  final ValueChanged<Duration>? onSeek;

  /// Callback when bar is tapped to expand
  final VoidCallback? onExpand;

  /// Height of the mini player bar
  final double miniHeight;

  /// Whether to show progress bar
  final bool showProgress;

  /// Whether the bar is expanded
  final bool isExpanded;

  const AudioPlayerBar({
    super.key,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onSeek,
    this.onExpand,
    this.miniHeight = 72,
    this.showProgress = true,
    this.isExpanded = false,
  });

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar>
    with SingleTickerProviderStateMixin {
  /// Animation controller for expand/collapse
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final currentSurah = provider.currentPlayingSurah;
    final isPlaying = provider.isPlaying;
    final progress = provider.playbackProgress;

    // Don't show if no surah is selected
    if (currentSurah == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onExpand,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) {
          widget.onExpand?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar at top
              if (widget.showProgress)
                _buildProgressBar(colorScheme, progress),

              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Surah info
                    Expanded(
                      child: _buildSurahInfo(theme, colorScheme, currentSurah),
                    ),

                    // Playback controls
                    _buildControls(colorScheme, isPlaying),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 1, end: 0);
  }

  /// Build progress bar at top of player bar
  Widget _buildProgressBar(ColorScheme colorScheme, double progress) {
    return LinearPercentIndicator(
      percent: progress.clamp(0.0, 1.0),
      backgroundColor: colorScheme.surfaceContainerHighest,
      progressColor: colorScheme.primary,
      lineHeight: 3,
      padding: EdgeInsets.zero,
      barRadius: const Radius.circular(2),
    );
  }

  /// Build surah info section
  Widget _buildSurahInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    SurahModel surah,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Surah number badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            surah.id.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Surah name
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                surah.nameArabic,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'الشيخ محمد صديق المنشاوي',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build playback controls
  Widget _buildControls(ColorScheme colorScheme, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: colorScheme.onSurface,
          ),
          onPressed: widget.onPrevious,
          tooltip: 'السورة السابقة',
        ),

        // Play/Pause button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            iconSize: 28,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: colorScheme.onPrimary,
            ),
            onPressed: widget.onPlayPause,
            tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
          ),
        ),

        // Next button
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: colorScheme.onSurface,
          ),
          onPressed: widget.onNext,
          tooltip: 'السورة التالية',
        ),
      ],
    );
  }
}

/// Full screen audio player widget
class FullScreenPlayer extends StatefulWidget {
  /// Callback when close is tapped
  final VoidCallback? onClose;

  /// Callback when play/pause is tapped
  final VoidCallback? onPlayPause;

  /// Callback when next is tapped
  final VoidCallback? onNext;

  /// Callback when previous is tapped
  final VoidCallback? onPrevious;

  /// Callback when seek is performed
  final ValueChanged<Duration>? onSeek;

  /// Callback when rewind is tapped
  final VoidCallback? onRewind;

  /// Callback when fast forward is tapped
  final VoidCallback? onFastForward;

  /// Callback when speed change
  final ValueChanged<double>? onSpeedChange;

  const FullScreenPlayer({
    super.key,
    this.onClose,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onSeek,
    this.onRewind,
    this.onFastForward,
    this.onSpeedChange,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with SingleTickerProviderStateMixin {
  /// Current playback speed
  double _currentSpeed = 1.0;

  /// Animation controller for artwork
  AnimationController? _artworkAnimationController;

  @override
  void initState() {
    super.initState();
    _artworkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _artworkAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final currentSurah = provider.currentPlayingSurah;
    final isPlaying = provider.isPlaying;
    final position = provider.currentPosition;
    final duration = provider.totalDuration;
    final progress = provider.playbackProgress;

    if (currentSurah == null) {
      return const SizedBox.shrink();
    }

    // Start/stop artwork animation based on playing state
    if (isPlaying) {
      _artworkAnimationController?.repeat();
    } else {
      _artworkAnimationController?.stop();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(theme, colorScheme),

              // Artwork
              Expanded(
                flex: 3,
                child: _buildArtwork(colorScheme, isPlaying),
              ),

              // Surah info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildSurahInfo(theme, colorScheme, currentSurah),
              ),

              const SizedBox(height: 24),

              // Progress slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProgressSlider(
                  theme,
                  colorScheme,
                  position,
                  duration,
                  progress,
                ),
              ),

              const SizedBox(height: 16),

              // Main controls
              _buildMainControls(colorScheme, isPlaying),

              const SizedBox(height: 16),

              // Secondary controls
              _buildSecondaryControls(colorScheme),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Build app bar
  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: colorScheme.onSurface,
              size: 32,
            ),
            onPressed: widget.onClose,
            tooltip: 'إغلاق',
          ),
          Text(
            'قيد التشغيل',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface,
            ),
            onPressed: () => _showOptionsBottomSheet(context),
            tooltip: 'خيارات',
          ),
        ],
      ),
    );
  }

  /// Build artwork section
  Widget _buildArtwork(ColorScheme colorScheme, bool isPlaying) {
    return Center(
      child: AnimatedBuilder(
        animation: _artworkAnimationController!,
        builder: (context, child) {
          return Transform.rotate(
            angle: _artworkAnimationController!.value * 2 * 3.14159,
            child: child,
          );
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.menu_book,
              size: 80,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Build surah info section
  Widget _buildSurahInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    SurahModel surah,
  ) {
    return Column(
      children: [
        Text(
          surah.nameArabic,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${surah.nameEnglish} • ${surah.versesCount} آية',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            surah.type,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Build progress slider
  Widget _buildProgressSlider(
    ThemeData theme,
    ColorScheme colorScheme,
    Duration position,
    Duration duration,
    double progress,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              widget.onSeek?.call(newPosition);
            },
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceContainerHighest,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build main playback controls
  Widget _buildMainControls(ColorScheme colorScheme, bool isPlaying) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10 seconds
        IconButton(
          icon: Icon(
            Icons.replay_10,
            color: colorScheme.onSurface,
            size: 32,
          ),
          onPressed: widget.onRewind,
          tooltip: 'ترجيع 10 ثواني',
        ),

        const SizedBox(width: 24),

        // Previous
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.skip_previous,
              color: colorScheme.onSurface,
            ),
            iconSize: 32,
            onPressed: widget.onPrevious,
            tooltip: 'السورة السابقة',
          ),
        ),

        const SizedBox(width: 16),

        // Play/Pause
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: colorScheme.onPrimary,
            ),
            iconSize: 40,
            onPressed: widget.onPlayPause,
            tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
          ),
        ),

        const SizedBox(width: 16),

        // Next
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.skip_next,
              color: colorScheme.onSurface,
            ),
            iconSize: 32,
            onPressed: widget.onNext,
            tooltip: 'السورة التالية',
          ),
        ),

        const SizedBox(width: 24),

        // Forward 10 seconds
        IconButton(
          icon: Icon(
            Icons.forward_10,
            color: colorScheme.onSurface,
            size: 32,
          ),
          onPressed: widget.onFastForward,
          tooltip: 'تقديم 10 ثواني',
        ),
      ],
    );
  }

  /// Build secondary controls
  Widget _buildSecondaryControls(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speed control
        TextButton.icon(
          icon: const Icon(Icons.speed, size: 20),
          label: Text('${_currentSpeed}x'),
          onPressed: () => _showSpeedDialog(context),
        ),

        // Sleep timer
        TextButton.icon(
          icon: const Icon(Icons.timer_outlined, size: 20),
          label: const Text('مؤقت'),
          onPressed: () => _showSleepTimerDialog(context),
        ),

        // Share
        TextButton.icon(
          icon: const Icon(Icons.share, size: 20),
          label: const Text('مشاركة'),
          onPressed: () => _shareSurah(context),
        ),
      ],
    );
  }

  /// Format duration to mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Show options bottom sheet
  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: const Text('إضافة إلى قائمة التشغيل'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('إضافة للمفضلة'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('تحميل السورة'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('مشاركة'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show speed dialog
  void _showSpeedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('سرعة التشغيل'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ChoiceChip(
                label: Text('${speed}x'),
                selected: _currentSpeed == speed,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSpeed = speed;
                    });
                    widget.onSpeedChange?.call(speed);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  /// Show sleep timer dialog
  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤقت النوم',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTimerChip(context, '15 دقيقة', const Duration(minutes: 15)),
                    _buildTimerChip(context, '30 دقيقة', const Duration(minutes: 30)),
                    _buildTimerChip(context, '45 دقيقة', const Duration(minutes: 45)),
                    _buildTimerChip(context, 'ساعة', const Duration(hours: 1)),
                    _buildTimerChip(context, 'نهاية السورة', Duration.zero),
                    _buildTimerChip(context, 'إلغاء', null),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build timer chip
  Widget _buildTimerChip(BuildContext context, String label, Duration? duration) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        // Handle timer setting
      },
    );
  }

  /// Share surah
  void _shareSurah(BuildContext context) {
    // Implement sharing functionality
  }
}

/// Mini player widget for bottom navigation bar
class MiniPlayer extends StatelessWidget {
  /// Callback when play/pause is tapped
  final VoidCallback? onPlayPause;

  /// Callback when tapped to expand
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.onPlayPause,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final currentSurah = provider.currentPlayingSurah;
    final isPlaying = provider.isPlaying;
    final progress = provider.playbackProgress;

    if (currentSurah == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 4,
              height: 48,
              child: LinearPercentIndicator(
                percent: progress.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                progressColor: colorScheme.primary,
                lineHeight: 48,
                width: 4,
                padding: EdgeInsets.zero,
                isRTL: true,
              ),
            ),

            // Surah info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentSurah.id.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentSurah.nameArabic,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'الشيخ المنشاوي',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play/Pause button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: colorScheme.primary,
              ),
              onPressed: onPlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
