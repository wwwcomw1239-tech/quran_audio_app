import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../data/surahs_data.dart';
import '../models/surah_model.dart';
import '../providers/quran_provider.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/download_stats_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/surah_card.dart';
import 'surah_player_screen.dart';

/// Home screen displaying list of all Surahs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Scroll controller for the list
  final ScrollController _scrollController = ScrollController();

  /// Audio service instance
  final AudioServiceInstance _audioService = AudioServiceInstance();

  /// Download service instance
  final DownloadService _downloadService = DownloadService();

  /// Whether audio service is initialized
  bool _isAudioInitialized = false;

  /// Show search bar
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize data and services
  Future<void> _initializeData() async {
    // Initialize provider
    await context.read<QuranProvider>().initialize();

    // Initialize audio service
    try {
      await _audioService.initialize();
      _isAudioInitialized = true;
    } catch (e) {
      debugPrint('Audio service initialization failed: $e');
    }

    // Load download status for all surahs
    await _loadDownloadStatus();
  }

  /// Load download status for all surahs
  Future<void> _loadDownloadStatus() async {
    final provider = context.read<QuranProvider>();
    for (final surah in allSurahs) {
      final isDownloaded = await _downloadService.isSurahDownloaded(surah);
      if (isDownloaded) {
        provider.markAsDownloaded(surah.id);
      }
    }
  }

  /// Navigate to surah player screen
  void _navigateToPlayer(SurahModel surah) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SurahPlayerScreen(surah: surah),
      ),
    );
  }

  /// Play surah
  Future<void> _playSurah(SurahModel surah) async {
    final provider = context.read<QuranProvider>();

    if (!_isAudioInitialized) {
      try {
        await _audioService.initialize();
        _isAudioInitialized = true;
      } catch (e) {
        _showErrorSnackbar('فشل في تهيئة المشغل');
        return;
      }
    }

    provider.setCurrentSurah(surah);
    await _audioService.playSurah(surah);
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

  /// Download surah
  Future<void> _downloadSurah(SurahModel surah) async {
    final provider = context.read<QuranProvider>();

    await _downloadService.downloadSurah(
      surah,
      onProgress: (progress) {
        provider.updateDownloadProgress(surah.id, progress);
      },
      onStatusChanged: (status) {
        if (status == DownloadStatus.completed) {
          provider.markAsDownloaded(surah.id);
          _showSuccessSnackbar('تم تحميل ${surah.nameArabic}');
        } else if (status == DownloadStatus.failed) {
          _showErrorSnackbar('فشل تحميل ${surah.nameArabic}');
        }
      },
    );
  }

  /// Toggle favorite
  void _toggleFavorite(SurahModel surah) {
    final provider = context.read<QuranProvider>();
    provider.toggleFavorite(surah.id);

    final message = surah.isFavorite
        ? 'تمت إزالة ${surah.nameArabic} من المفضلة'
        : 'تمت إضافة ${surah.nameArabic} إلى المفضلة';
    _showSuccessSnackbar(message);
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Scroll to top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<QuranProvider>();
    final filteredSurahs = provider.filteredSurahs;
    final currentPlayingSurah = provider.currentPlayingSurah;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(theme, colorScheme, provider),
          ];
        },
        body: Column(
          children: [
            // Search bar (when visible)
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SearchBarWidget(
                  onSearchChanged: (query) {
                    provider.setSearchQuery(query);
                  },
                  hintText: 'ابحث عن سورة...',
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),

            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
              child: FilterChipsWidget(
                onFilterChanged: (filter) {
                  _scrollToTop();
                },
              ),
            ),

            // Download stats card
            const DownloadStatsCard(
              style: DownloadStatsStyle.compact,
            ),

            // Surah list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSurahs.isEmpty
                      ? _buildEmptyState(theme, colorScheme, provider)
                      : _buildSurahList(filteredSurahs),
            ),

            // Mini player bar
            if (currentPlayingSurah != null)
              AudioPlayerBar(
                onPlayPause: _togglePlayPause,
                onNext: () {
                  provider.playNextSurah();
                  if (provider.currentPlayingSurah != null) {
                    _playSurah(provider.currentPlayingSurah!);
                  }
                },
                onPrevious: () {
                  provider.playPreviousSurah();
                  if (provider.currentPlayingSurah != null) {
                    _playSurah(provider.currentPlayingSurah!);
                  }
                },
                onExpand: () => _navigateToPlayer(currentPlayingSurah),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme, provider),
    );
  }

  /// Build sliver app bar
  Widget _buildSliverAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    QuranProvider provider,
  ) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      expandedHeight: 120,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
              ],
            ),
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القرآن الكريم',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'بصوت الشيخ محمد صديق المنشاوي',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Search button
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                provider.clearSearch();
              }
            });
          },
          tooltip: _showSearch ? 'إغلاق البحث' : 'بحث',
        ),

        // Download stats indicator
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: DownloadStatsIndicator(),
        ),
      ],
    );
  }

  /// Build surah list
  Widget _buildSurahList(List<SurahModel> surahs) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDownloadStatus();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          final surah = surahs[index];

          return SurahCard(
            surah: surah,
            onTap: () => _navigateToPlayer(surah),
            onPlayTap: () => _playSurah(surah),
            onDownloadTap: () => _downloadSurah(surah),
            onFavoriteTap: () => _toggleFavorite(surah),
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    QuranProvider provider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات أخرى أو تغيير الفلتر',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              provider.resetFilters();
              setState(() {
                _showSearch = false;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  /// Build floating action button
  Widget? _buildFloatingActionButton(
    ColorScheme colorScheme,
    QuranProvider provider,
  ) {
    final filteredSurahs = provider.filteredSurahs;

    if (filteredSurahs.isEmpty) return null;

    return FloatingActionButton(
      onPressed: _scrollToTop,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.arrow_upward,
        color: colorScheme.onPrimaryContainer,
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
