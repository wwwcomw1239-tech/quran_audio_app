import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/surah_model.dart';

/// Custom AudioHandler for background audio playback
/// Integrates with just_audio and audio_service packages
class QuranAudioHandler extends BaseAudioHandler {
  /// The underlying audio player
  final AudioPlayer _player = AudioPlayer();

  /// Current surah being played
  SurahModel? _currentSurah;

  /// Stream subscription for position updates
  StreamSubscription<Duration>? _positionSubscription;

  /// Stream subscription for duration updates
  StreamSubscription<Duration?>? _durationSubscription;

  /// Stream subscription for player state updates
  StreamSubscription<PlayerState>? _playerStateSubscription;

  /// Stream subscription for current index updates
  StreamSubscription<int?>? _currentIndexSubscription;

  /// Getter for current surah
  SurahModel? get currentSurah => _currentSurah;

  /// Stream of playback position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of playback duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Getter for current position
  Duration get position => _player.position;

  /// Getter for duration
  Duration? get duration => _player.duration;

  /// Getter for playing state
  bool get isPlaying => _player.playing;

  /// Getter for processing state
  ProcessingState get processingState => _player.processingState;

  /// Constructor - initializes the audio handler
  QuranAudioHandler() {
    _init();
  }

  /// Initialize the audio handler
  void _init() {
    // Broadcast media item changes
    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null) {
        _broadcastMediaItem();
      }
    });

    // Broadcast playback state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _broadcastState();
    });

    // Set initial playback state
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
        MediaAction.rewind,
        MediaAction.fastForward,
        MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: AudioProcessingState.ready,
      playing: false,
      speed: 1.0,
      updatePosition: Duration.zero,
      queueIndex: 0,
    ));
  }

  /// Broadcast current media item to audio service
  void _broadcastMediaItem() {
    if (_currentSurah != null) {
      mediaItem.add(MediaItem(
        id: _currentSurah!.id.toString(),
        title: _currentSurah!.nameArabic,
        album: 'القرآن الكريم',
        artist: 'الشيخ محمد صديق المنشاوي',
        artUri: Uri.parse('https://server8.mp3quran.net/minsh/'),
        duration: _player.duration ?? Duration.zero,
      ));
    }
  }

  /// Broadcast current playback state
  void _broadcastState() {
    final playerState = _player.playerState;
    final processingState = _mapProcessingState(playerState.processingState);

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        playerState.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.skipToPrevious,
        MediaAction.skipToNext,
        MediaAction.rewind,
        MediaAction.fastForward,
        MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: processingState,
      playing: playerState.playing,
      speed: _player.speed,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      queueIndex: 0,
    ));
  }

  /// Map just_audio ProcessingState to AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Play a specific surah
  Future<void> playSurah(SurahModel surah) async {
    _currentSurah = surah;

    String audioPath;

    // Check if surah is downloaded
    if (surah.isDownloaded) {
      final localPath = await getLocalAudioPath(surah);
      audioPath = localPath;
    } else {
      audioPath = surah.audioUrl;
    }

    try {
      // Set the audio source
      if (audioPath.startsWith('http')) {
        await _player.setUrl(audioPath);
      } else {
        await _player.setFilePath(audioPath);
      }

      // Broadcast media item
      _broadcastMediaItem();

      // Start playing
      await _player.play();
    } catch (e) {
      // Handle error
      playbackState.add(PlaybackState(
        processingState: AudioProcessingState.error,
        playing: false,
        updatePosition: Duration.zero,
      ));
      rethrow;
    }
  }

  /// Get local audio file path for downloaded surah
  Future<String> getLocalAudioPath(SurahModel surah) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/quran_audio');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return '${audioDir.path}/${surah.audioFileName}';
  }

  /// Check if surah audio file exists locally
  Future<bool> isSurahDownloaded(SurahModel surah) async {
    try {
      final localPath = await getLocalAudioPath(surah);
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size of downloaded audio
  Future<int> getDownloadedFileSize(SurahModel surah) async {
    try {
      final localPath = await getLocalAudioPath(surah);
      final file = File(localPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ============ AudioHandler implementations ============

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentSurah = null;
    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> rewind() async {
    final currentPosition = _player.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  @override
  Future<void> fastForward() async {
    final currentPosition = _player.position;
    final maxDuration = _player.duration ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 10);
    await _player.seek(
      newPosition > maxDuration ? maxDuration : newPosition,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    // This will be handled by the provider
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> skipToNext() async {
    // This will be handled by the provider
    await _player.seek(Duration.zero);
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Get current volume
  double get volume => _player.volume;

  /// Get current speed
  double get speed => _player.speed;

  /// Get loop mode
  LoopMode get loopMode => _player.loopMode;

  /// Release resources
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  /// Dispose the audio handler
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _player.dispose();
  }
}

/// Service class for managing audio playback
/// Provides a simplified interface for the app
class AudioServiceInstance {
  /// Singleton instance
  static final AudioServiceInstance _instance = AudioServiceInstance._internal();

  /// Factory constructor
  factory AudioServiceInstance() => _instance;

  /// Private constructor
  AudioServiceInstance._internal();

  /// Audio handler instance
  QuranAudioHandler? _audioHandler;

  /// Stream controller for position updates
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  /// Stream controller for duration updates
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  /// Stream controller for player state updates
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();

  /// Stream controller for error updates
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Stream of playback position
  Stream<Duration> get positionStream => _positionController.stream;

  /// Stream of playback duration
  Stream<Duration> get durationStream => _durationController.stream;

  /// Stream of player state
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  /// Stream of errors
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => QuranAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.quran.manshawy.audio',
          androidNotificationChannelName: 'القرآن الكريم',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      // Set up stream listeners
      _audioHandler!.positionStream.listen((position) {
        _positionController.add(position);
      });

      _audioHandler!.durationStream.listen((duration) {
        if (duration != null) {
          _durationController.add(duration);
        }
      });

      _audioHandler!.playerStateStream.listen((state) {
        _playerStateController.add(state);
      });
    } catch (e) {
      _errorController.add('فشل في تهيئة خدمة الصوت: ${e.toString()}');
      rethrow;
    }
  }

  /// Get the audio handler
  QuranAudioHandler? get audioHandler => _audioHandler;

  /// Play a surah
  Future<void> playSurah(SurahModel surah) async {
    if (_audioHandler == null) {
      await initialize();
    }
    await _audioHandler!.playSurah(surah);
  }

  /// Play
  Future<void> play() async {
    await _audioHandler?.play();
  }

  /// Pause
  Future<void> pause() async {
    await _audioHandler?.pause();
  }

  /// Stop
  Future<void> stop() async {
    await _audioHandler?.stop();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioHandler?.seek(position);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _audioHandler?.setSpeed(speed);
  }

  /// Rewind 10 seconds
  Future<void> rewind() async {
    await _audioHandler?.rewind();
  }

  /// Fast forward 10 seconds
  Future<void> fastForward() async {
    await _audioHandler?.fastForward();
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    await _audioHandler?.setVolume(volume);
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _audioHandler?.setLoopMode(mode);
  }

  /// Get current position
  Duration get position => _audioHandler?.position ?? Duration.zero;

  /// Get duration
  Duration? get duration => _audioHandler?.duration;

  /// Check if playing
  bool get isPlaying => _audioHandler?.isPlaying ?? false;

  /// Get current surah
  SurahModel? get currentSurah => _audioHandler?.currentSurah;

  /// Get local audio path
  Future<String> getLocalAudioPath(SurahModel surah) async {
    return await _audioHandler!.getLocalAudioPath(surah);
  }

  /// Check if surah is downloaded
  Future<bool> isSurahDownloaded(SurahModel surah) async {
    if (_audioHandler == null) {
      await initialize();
    }
    return await _audioHandler!.isSurahDownloaded(surah);
  }

  /// Dispose the service
  void dispose() {
    _audioHandler?.dispose();
    _positionController.close();
    _durationController.close();
    _playerStateController.close();
    _errorController.close();
  }
}
