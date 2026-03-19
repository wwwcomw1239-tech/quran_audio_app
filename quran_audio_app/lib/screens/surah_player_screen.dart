import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/surah_model.dart';
import '../providers/quran_provider.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';

/// Surah player screen for full audio playback experience
class SurahPlayerScreen extends StatefulWidget {
  /// The surah to play
  final SurahModel surah;

  /// Whether to auto-play on load
  final bool autoPlay;

  const SurahPlayerScreen({
    super.key,
    required this.surah,
    this.autoPlay = true,
  });

  @override
  State<SurahPlayerScreen> createState() => _SurahPlayerScreenState();
}

class _SurahPlayerScreenState extends State<SurahPlayerScreen>
    with TickerProviderStateMixin {
  /// Audio service instance
  final AudioServiceInstance _audioService = AudioServiceInstance();

  /// Download service instance
  final DownloadService _downloadService = DownloadService();

  /// Animation controller for artwork
  late AnimationController _artworkAnimationController;

  /// Animation controller for controls
  late AnimationController _controlsAnimationController;

  /// Whether controls are visible
  bool _controlsVisible = true;

  /// Current playback speed
  double _currentSpeed = 1.0;

  /// Current loop mode
  LoopMode _loopMode = LoopMode.off;

  /// Whether surah is downloaded
  bool _isDownloaded = false;

  /// Download progress
  double _downloadProgress = 0.0;

  /// Whether is downloading
  bool _isDownloading = false;

  /// Stream subscription for position
  StreamSubscription<Duration>? _positionSubscription;

  /// Stream subscription for duration
  StreamSubscription<Duration>? _durationSubscription;

  /// Stream subscription for player state
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    _artworkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initializePlayer();
    _checkDownloadStatus();
  }

  /// Initialize audio player
  Future<void> _initializePlayer() async {
    try {
      await _audioService.initialize();

      // Set up stream listeners
      _positionSubscription = _audioService.positionStream.listen((position) {
        if (mounted) {
          context.read<QuranProvider>().updatePosition(position);
        }
      });

      _durationSubscription = _audioService.durationStream.listen((duration) {
        if (mounted) {
          context.read<QuranProvider>().updateDuration(duration);
        }
      });

      _playerStateSubscription =
          _audioService.playerStateStream.listen((state) {
        if (mounted) {
          if (state.playing) {
            _artworkAnimationController.repeat();
          } else {
            _artworkAnimationController.stop();
          }
        }
      });

      // Set current surah in provider
      context.read<QuranProvider>().setCurrentSurah(widget.surah);

      // Auto-play if requested
      if (widget.autoPlay) {
        await _audioService.playSurah(widget.surah);
      }
    } catch (e) {
      _showErrorSnackbar('فشل في تحميل الصوت: ${e.toString()}');
    }
  }

  /// Check if surah is downloaded
  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await _downloadService.isSurahDownloaded(widget.surah);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  /// Download surah
  Future<void> _downloadSurah() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final success = await _downloadService.downloadSurah(
      widget.surah,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onStatusChanged: (status) {
        if (status == DownloadStatus.completed && mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          context.read<QuranProvider>().markAsDownloaded(widget.surah.id);
        } else if (status == DownloadStatus.failed && mounted) {
          setState(() {
            _isDownloading = false;
          });
          _showErrorSnackbar('فشل في تحميل السورة');
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  /// Toggle play/pause
  Future<void> _togglePlayPause() async {
    final provider = context.read<QuranProvider>();
    if (provider.isPlaying) {
      await _audioService.pause();
      provider.setPlaying(false);
    } else {
      await _audioService.play();
      provider.setPlaying(true);
    }
  }

  /// Seek to position
  Future<void> _seekTo(Duration position) async {
    await _audioService.seek(position);
    context.read<QuranProvider>().updatePosition(position);
  }

  /// Rewind 10 seconds
  Future<void> _rewind() async {
    final currentPosition = _audioService.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await _seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  /// Fast forward 10 seconds
  Future<void> _fastForward() async {
    final currentPosition = _audioService.position;
    final duration = _audioService.duration ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 10);
    await _seekTo(newPosition > duration ? duration : newPosition);
  }

  /// Play next surah
  void _playNext() {
    final provider = context.read<QuranProvider>();
    provider.playNextSurah();
    if (provider.currentPlayingSurah != null) {
      _audioService.playSurah(provider.currentPlayingSurah!);
    }
  }

  /// Play previous surah
  void _playPrevious() {
    final provider = context.read<QuranProvider>();
    provider.playPreviousSurah();
    if (provider.currentPlayingSurah != null) {
      _audioService.playSurah(provider.currentPlayingSurah!);
    }
  }

  /// Set playback speed
  Future<void> _setSpeed(double speed) async {
    await _audioService.setSpeed(speed);
    setState(() {
      _currentSpeed = speed;
    });
  }

  /// Toggle loop mode
  Future<void> _toggleLoopMode() async {
    LoopMode newMode;
    switch (_loopMode) {
      case LoopMode.off:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.off;
        break;
    }
    await _audioService.setLoopMode(newMode);
    setState(() {
      _loopMode = newMode;
    });
  }

  /// Toggle favorite
  void _toggleFavorite() {
    context.read<QuranProvider>().toggleFavorite(widget.surah.id);
  }

  /// Toggle controls visibility
  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Format duration to mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _artworkAnimationController.dispose();
    _controlsAnimationController.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();

    final currentSurah = provider.currentPlayingSurah ?? widget.surah;
    final isPlaying = provider.isPlaying;
    final position = provider.currentPosition;
    final duration = provider.totalDuration;
    final progress = provider.playbackProgress;
    final isFavorite = provider.isFavorite(currentSurah.id);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.4),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(theme, colorScheme, currentSurah, isFavorite),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Artwork
                      _buildArtwork(colorScheme, isPlaying),

                      const SizedBox(height: 32),

                      // Surah info
                      _buildSurahInfo(theme, colorScheme, currentSurah),

                      const SizedBox(height: 32),

                      // Progress slider
                      _buildProgressSlider(
                        theme,
                        colorScheme,
                        position,
                        duration,
                        progress,
                      ),

                      const SizedBox(height: 24),

                      // Main controls
                      _buildMainControls(colorScheme, isPlaying),

                      const SizedBox(height: 24),

                      // Secondary controls
                      _buildSecondaryControls(colorScheme),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              _buildBottomBar(colorScheme),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Build app bar
  Widget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    SurahModel surah,
    bool isFavorite,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: colorScheme.onSurface,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'رجوع',
          ),

          // Title
          Expanded(
            child: Column(
              children: [
                Text(
                  'قيد التشغيل',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  surah.nameArabic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Favorite button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFavorite
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
          ),

          // More options
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_vert,
                color: colorScheme.onSurface,
              ),
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
    return GestureDetector(
      onTap: _toggleControls,
      child: AnimatedBuilder(
        animation: _artworkAnimationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _artworkAnimationController.value * 2 * 3.14159,
            child: child,
          );
        },
        child: Container(
          width: 220,
          height: 220,
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
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.menu_book_rounded,
              size: 100,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'المنشاوي',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                _seekTo(newPosition);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build main playback controls
  Widget _buildMainControls(ColorScheme colorScheme, bool isPlaying) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10 seconds
        _buildControlButton(
          icon: Icons.replay_10,
          size: 36,
          onPressed: _rewind,
          tooltip: 'ترجيع 10 ثواني',
        ),

        const SizedBox(width: 20),

        // Previous
        _buildControlButton(
          icon: Icons.skip_previous,
          size: 40,
          onPressed: _playPrevious,
          tooltip: 'السورة السابقة',
          hasBackground: true,
        ),

        const SizedBox(width: 16),

        // Play/Pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 48,
              color: colorScheme.onPrimary,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Next
        _buildControlButton(
          icon: Icons.skip_next,
          size: 40,
          onPressed: _playNext,
          tooltip: 'السورة التالية',
          hasBackground: true,
        ),

        const SizedBox(width: 20),

        // Forward 10 seconds
        _buildControlButton(
          icon: Icons.forward_10,
          size: 36,
          onPressed: _fastForward,
          tooltip: 'تقديم 10 ثواني',
        ),
      ],
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
    required String tooltip,
    bool hasBackground = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (hasBackground) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: size),
          color: colorScheme.onSurface,
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, size: size),
      color: colorScheme.onSurface,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  /// Build secondary controls
  Widget _buildSecondaryControls(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speed control
          _buildSecondaryButton(
            icon: Icons.speed,
            label: '${_currentSpeed}x',
            onTap: () => _showSpeedDialog(context),
          ),

          // Loop mode
          _buildSecondaryButton(
            icon: _loopMode == LoopMode.off
                ? Icons.repeat
                : _loopMode == LoopMode.one
                    ? Icons.repeat_one
                    : Icons.repeat,
            label: _loopMode == LoopMode.off
                ? 'تكرار'
                : _loopMode == LoopMode.one
                    ? 'واحدة'
                    : 'الكل',
            onTap: _toggleLoopMode,
            isActive: _loopMode != LoopMode.off,
          ),

          // Sleep timer
          _buildSecondaryButton(
            icon: Icons.timer_outlined,
            label: 'مؤقت',
            onTap: () => _showSleepTimerDialog(context),
          ),

          // Download
          _buildDownloadButton(colorScheme),
        ],
      ),
    );
  }

  /// Build secondary button
  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build download button
  Widget _buildDownloadButton(ColorScheme colorScheme) {
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: _downloadProgress,
                strokeWidth: 2,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    if (_isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_done,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 4),
            Text(
              'محملة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSecondaryButton(
      icon: Icons.download,
      label: 'تحميل',
      onTap: _downloadSurah,
    );
  }

  /// Build bottom bar
  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomButton(
            icon: Icons.list,
            label: 'السور',
            onTap: () => Navigator.of(context).pop(),
          ),
          _buildBottomButton(
            icon: Icons.playlist_play,
            label: 'قائمة التشغيل',
            onTap: () => _showPlaylistBottomSheet(context),
          ),
          _buildBottomButton(
            icon: Icons.share,
            label: 'مشاركة',
            onTap: () => _shareSurah(),
          ),
        ],
      ),
    );
  }

  /// Build bottom button
  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Show options bottom sheet
  void _showOptionsBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('معلومات السورة'),
                onTap: () {
                  Navigator.pop(context);
                  _showSurahInfoDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('إضافة علامة مرجعية'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.favorite_border,
                  color: colorScheme.error,
                ),
                title: Text(
                  'إضافة للمفضلة',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('مشاركة'),
                onTap: () {
                  Navigator.pop(context);
                  _shareSurah();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Show playlist bottom sheet
  void _showPlaylistBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<QuranProvider>();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'السور المجاورة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final surahId = (widget.surah.id - 2 + index).clamp(1, 114);
                    final surah = provider.filteredSurahs.firstWhere(
                      (s) => s.id == surahId,
                      orElse: () => widget.surah,
                    );
                    final isCurrentSurah = surah.id == widget.surah.id;

                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrentSurah
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          surah.id.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentSurah
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameArabic,
                        style: TextStyle(
                          fontWeight: isCurrentSurah
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentSurah
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        surah.nameEnglish,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: isCurrentSurah
                          ? Icon(
                              Icons.play_circle,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: isCurrentSurah
                          ? null
                          : () {
                              Navigator.pop(context);
                              _audioService.playSurah(surah);
                              context.read<QuranProvider>().setCurrentSurah(surah);
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                    _setSpeed(speed);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤقت النوم',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTimerChip(context, '15 دقيقة'),
                    _buildTimerChip(context, '30 دقيقة'),
                    _buildTimerChip(context, '45 دقيقة'),
                    _buildTimerChip(context, 'ساعة'),
                    _buildTimerChip(context, 'نهاية السورة'),
                    _buildTimerChip(context, 'إلغاء المؤقت'),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build timer chip
  Widget _buildTimerChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        // Handle timer setting
      },
    );
  }

  /// Show surah info dialog
  void _showSurahInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.surah.nameArabic),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('الاسم بالإنجليزية', widget.surah.nameEnglish),
              _buildInfoRow('رقم السورة', widget.surah.id.toString()),
              _buildInfoRow('نوع السورة', widget.surah.type),
              _buildInfoRow('عدد الآيات', widget.surah.versesCount.toString()),
              _buildInfoRow('القارئ', 'الشيخ محمد صديق المنشاوي'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Share surah
  void _shareSurah() {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة خاصية المشاركة قريباً'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
