import 'package:flutter/material.dart';

import '../models/surah_model.dart';
import '../data/surahs_data.dart';

/// Filter types for surah list
enum FilterType {
  /// Show all surahs
  all,
  /// Show only Meccan surahs
  makki,
  /// Show only Medinan surahs
  madani,
  /// Show only favorite surahs
  favorites,
}

/// Provider for managing Quran app state
/// Handles surah filtering, favorites, and playback state
class QuranProvider extends ChangeNotifier {
  /// List of surahs after applying current filters
  List<SurahModel> _filteredSurahs = List.from(allSurahs);

  /// Current active filter
  FilterType _currentFilter = FilterType.all;

  /// Current search query
  String _searchQuery = '';

  /// Currently playing surah
  SurahModel? _currentPlayingSurah;

  /// Whether audio is currently playing
  bool _isPlaying = false;

  /// Current playback position in seconds
  Duration _currentPosition = Duration.zero;

  /// Total duration of current audio
  Duration _totalDuration = Duration.zero;

  /// Loading state
  bool _isLoading = false;

  /// Error message if any
  String? _errorMessage;

  // ============ GETTERS ============

  /// Get filtered list of surahs
  List<SurahModel> get filteredSurahs => _filteredSurahs;

  /// Get current filter type
  FilterType get currentFilter => _currentFilter;

  /// Get current search query
  String get searchQuery => _searchQuery;

  /// Get currently playing surah
  SurahModel? get currentPlayingSurah => _currentPlayingSurah;

  /// Check if audio is playing
  bool get isPlaying => _isPlaying;

  /// Get current playback position
  Duration get currentPosition => _currentPosition;

  /// Get total duration
  Duration get totalDuration => _totalDuration;

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Get count of downloaded surahs
  int get downloadedCount => allSurahs.where((s) => s.isDownloaded).length;

  /// Get count of favorite surahs
  int get favoriteCount => allSurahs.where((s) => s.isFavorite).length;

  /// Get playback progress as percentage (0.0 to 1.0)
  double get playbackProgress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  /// Check if a specific surah is currently playing
  bool isSurahPlaying(int surahId) {
    return _currentPlayingSurah?.id == surahId && _isPlaying;
  }

  // ============ FILTER METHODS ============

  /// Set filter type and apply filters
  void setFilter(FilterType filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Set search query and apply filters
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Apply current filter and search query to surah list
  void _applyFilters() {
    List<SurahModel> list = List<SurahModel>.from(allSurahs);

    // Apply type filter
    switch (_currentFilter) {
      case FilterType.makki:
        list = list.where((s) => s.type == 'مكية').toList();
        break;
      case FilterType.madani:
        list = list.where((s) => s.type == 'مدنية').toList();
        break;
      case FilterType.favorites:
        list = list.where((s) => s.isFavorite).toList();
        break;
      case FilterType.all:
        // No filter needed
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      list = list.where((s) {
        return s.nameArabic.contains(_searchQuery) ||
            s.nameEnglish.toLowerCase().contains(queryLower) ||
            s.id.toString().contains(_searchQuery);
      }).toList();
    }

    _filteredSurahs = list;
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Reset all filters
  void resetFilters() {
    _currentFilter = FilterType.all;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // ============ PLAYBACK METHODS ============

  /// Set current playing surah
  void setCurrentSurah(SurahModel surah) {
    _currentPlayingSurah = surah;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  /// Toggle play/pause state
  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  /// Set playing state
  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  /// Update playback position
  void updatePosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  /// Update total duration
  void updateDuration(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  /// Stop playback
  void stopPlayback() {
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  /// Play next surah
  void playNextSurah() {
    if (_currentPlayingSurah == null) {
      if (allSurahs.isNotEmpty) {
        setCurrentSurah(allSurahs.first);
      }
      return;
    }

    final currentIndex = allSurahs.indexWhere((s) => s.id == _currentPlayingSurah!.id);
    if (currentIndex < allSurahs.length - 1) {
      setCurrentSurah(allSurahs[currentIndex + 1]);
    } else {
      // Loop back to first surah
      setCurrentSurah(allSurahs.first);
    }
  }

  /// Play previous surah
  void playPreviousSurah() {
    if (_currentPlayingSurah == null) {
      if (allSurahs.isNotEmpty) {
        setCurrentSurah(allSurahs.last);
      }
      return;
    }

    final currentIndex = allSurahs.indexWhere((s) => s.id == _currentPlayingSurah!.id);
    if (currentIndex > 0) {
      setCurrentSurah(allSurahs[currentIndex - 1]);
    } else {
      // Loop to last surah
      setCurrentSurah(allSurahs.last);
    }
  }

  // ============ FAVORITES METHODS ============

  /// Toggle favorite status for a surah
  void toggleFavorite(int surahId) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1) {
      allSurahs[index].isFavorite = !allSurahs[index].isFavorite;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Check if a surah is favorite
  bool isFavorite(int surahId) {
    final surah = allSurahs.firstWhere((s) => s.id == surahId, orElse: () => allSurahs.first);
    return surah.isFavorite;
  }

  /// Add surah to favorites
  void addToFavorites(int surahId) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1 && !allSurahs[index].isFavorite) {
      allSurahs[index].isFavorite = true;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Remove surah from favorites
  void removeFromFavorites(int surahId) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1 && allSurahs[index].isFavorite) {
      allSurahs[index].isFavorite = false;
      _applyFilters();
      notifyListeners();
    }
  }

  // ============ DOWNLOAD METHODS ============

  /// Update download progress for a surah
  void updateDownloadProgress(int surahId, double progress) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1) {
      allSurahs[index].downloadProgress = progress.clamp(0.0, 1.0);
      if (progress >= 1.0) {
        allSurahs[index].isDownloaded = true;
      }
      notifyListeners();
    }
  }

  /// Mark surah as downloaded
  void markAsDownloaded(int surahId) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1) {
      allSurahs[index].isDownloaded = true;
      allSurahs[index].downloadProgress = 1.0;
      notifyListeners();
    }
  }

  /// Mark surah as not downloaded
  void markAsNotDownloaded(int surahId) {
    final index = allSurahs.indexWhere((s) => s.id == surahId);
    if (index != -1) {
      allSurahs[index].isDownloaded = false;
      allSurahs[index].downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Get download progress for a surah
  double getDownloadProgress(int surahId) {
    final surah = allSurahs.firstWhere((s) => s.id == surahId, orElse: () => allSurahs.first);
    return surah.downloadProgress;
  }

  /// Check if surah is downloaded
  bool isDownloaded(int surahId) {
    final surah = allSurahs.firstWhere((s) => s.id == surahId, orElse: () => allSurahs.first);
    return surah.isDownloaded;
  }

  // ============ STATE MANAGEMENT ============

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load saved favorites and download states from SharedPreferences
      // This will be implemented when integrating SharedPreferences
      await Future<void>.delayed(const Duration(milliseconds: 500)); // Simulated delay

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _filteredSurahs = List.from(allSurahs);
    _currentFilter = FilterType.all;
    _searchQuery = '';
    _currentPlayingSurah = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}
