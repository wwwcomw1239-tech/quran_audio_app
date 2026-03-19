import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/surah_model.dart';

/// Callback type for download progress
typedef DownloadProgressCallback = void Function(double progress);

/// Callback type for download status
typedef DownloadStatusCallback = void Function(DownloadStatus status);

/// Download status enum
enum DownloadStatus {
  /// Download is idle
  idle,
  /// Download is in progress
  downloading,
  /// Download is completed
  completed,
  /// Download has failed
  failed,
  /// Download was cancelled
  cancelled,
  /// Download was paused
  paused,
}

/// Model for download task
class DownloadTask {
  /// The surah being downloaded
  final SurahModel surah;

  /// Current download progress (0.0 to 1.0)
  double progress;

  /// Current download status
  DownloadStatus status;

  /// Total bytes to download
  int totalBytes;

  /// Bytes downloaded so far
  int downloadedBytes;

  /// Error message if failed
  String? errorMessage;

  /// Stream controller for progress updates
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  /// Stream controller for status updates
  final StreamController<DownloadStatus> _statusController =
      StreamController<DownloadStatus>.broadcast();

  /// Stream of progress updates
  Stream<double> get progressStream => _progressController.stream;

  /// Stream of status updates
  Stream<DownloadStatus> get statusStream => _statusController.stream;

  /// Cancel token for aborting download
  bool _isCancelled = false;

  /// Constructor
  DownloadTask({
    required this.surah,
    this.progress = 0.0,
    this.status = DownloadStatus.idle,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
  });

  /// Cancel the download
  void cancel() {
    _isCancelled = true;
    status = DownloadStatus.cancelled;
    _statusController.add(status);
  }

  /// Check if download is cancelled
  bool get isCancelled => _isCancelled;

  /// Update progress
  void updateProgress(double newProgress) {
    progress = newProgress;
    _progressController.add(progress);
  }

  /// Update status
  void updateStatus(DownloadStatus newStatus) {
    status = newStatus;
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}

/// Service for downloading Quran audio files
class DownloadService {
  /// Singleton instance
  static final DownloadService _instance = DownloadService._internal();

  /// Factory constructor
  factory DownloadService() => _instance;

  /// Private constructor
  DownloadService._internal();

  /// Map of active download tasks
  final Map<int, DownloadTask> _activeTasks = {};

  /// Stream controller for download updates
  final StreamController<DownloadEvent> _eventController =
      StreamController<DownloadEvent>.broadcast();

  /// Stream of download events
  Stream<DownloadEvent> get eventStream => _eventController.stream;

  /// Base URL for Quran audio files
  static const String baseUrl = 'https://server8.mp3quran.net/minsh/';

  /// Get the local directory for storing audio files
  Future<Directory> getAudioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/quran_audio');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return audioDir;
  }

  /// Get the local file path for a surah
  Future<String> getLocalFilePath(SurahModel surah) async {
    final audioDir = await getAudioDirectory();
    return '${audioDir.path}/${surah.audioFileName}';
  }

  /// Check if a surah is already downloaded
  Future<bool> isSurahDownloaded(SurahModel surah) async {
    try {
      final filePath = await getLocalFilePath(surah);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get the file size of a downloaded surah
  Future<int> getDownloadedFileSize(SurahModel surah) async {
    try {
      final filePath = await getLocalFilePath(surah);
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get total size of all downloaded files
  Future<int> getTotalDownloadedSize() async {
    try {
      final audioDir = await getAudioDirectory();
      if (!await audioDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size to human readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get the remote file size without downloading
  Future<int?> getRemoteFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      final contentLength = response.headers['content-length'];
      if (contentLength != null) {
        return int.parse(contentLength);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download a surah
  Future<bool> downloadSurah(
    SurahModel surah, {
    DownloadProgressCallback? onProgress,
    DownloadStatusCallback? onStatusChanged,
  }) async {
    // Check if already downloading
    if (_activeTasks.containsKey(surah.id)) {
      final existingTask = _activeTasks[surah.id]!;
      if (existingTask.status == DownloadStatus.downloading) {
        return false;
      }
    }

    // Create download task
    final task = DownloadTask(
      surah: surah,
      status: DownloadStatus.downloading,
    );
    _activeTasks[surah.id] = task;

    // Notify status changed
    onStatusChanged?.call(DownloadStatus.downloading);
    _eventController.add(DownloadEvent(
      surahId: surah.id,
      status: DownloadStatus.downloading,
      progress: 0.0,
    ));

    try {
      final url = surah.audioUrl;
      final filePath = await getLocalFilePath(surah);
      final file = File(filePath);

      // Create parent directory if not exists
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // Start download
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      // Get total content length
      final contentLength = response.contentLength ?? 0;
      task.totalBytes = contentLength;

      // Create file sink
      final sink = file.openWrite();

      int downloadedBytes = 0;

      // Stream the response to file
      await for (final chunk in response.stream) {
        // Check if cancelled
        if (task.isCancelled) {
          await sink.close();
          await file.delete();
          _activeTasks.remove(surah.id);
          onStatusChanged?.call(DownloadStatus.cancelled);
          _eventController.add(DownloadEvent(
            surahId: surah.id,
            status: DownloadStatus.cancelled,
            progress: task.progress,
          ));
          return false;
        }

        // Write chunk to file
        sink.add(chunk);
        downloadedBytes += chunk.length;
        task.downloadedBytes = downloadedBytes;

        // Calculate progress
        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          task.updateProgress(progress);
          onProgress?.call(progress);
          _eventController.add(DownloadEvent(
            surahId: surah.id,
            status: DownloadStatus.downloading,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: contentLength,
          ));
        }
      }

      // Close file sink
      await sink.close();

      // Mark as completed
      task.updateProgress(1.0);
      task.updateStatus(DownloadStatus.completed);
      onProgress?.call(1.0);
      onStatusChanged?.call(DownloadStatus.completed);
      _eventController.add(DownloadEvent(
        surahId: surah.id,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: downloadedBytes,
        totalBytes: contentLength,
      ));

      _activeTasks.remove(surah.id);
      return true;
    } catch (e) {
      // Handle error
      task.updateStatus(DownloadStatus.failed);
      task.errorMessage = e.toString();
      onStatusChanged?.call(DownloadStatus.failed);
      _eventController.add(DownloadEvent(
        surahId: surah.id,
        status: DownloadStatus.failed,
        progress: task.progress,
        errorMessage: e.toString(),
      ));

      // Clean up partial file
      try {
        final filePath = await getLocalFilePath(surah);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      _activeTasks.remove(surah.id);
      return false;
    }
  }

  /// Cancel a download
  void cancelDownload(int surahId) {
    if (_activeTasks.containsKey(surahId)) {
      _activeTasks[surahId]!.cancel();
    }
  }

  /// Cancel all downloads
  void cancelAllDownloads() {
    for (final task in _activeTasks.values) {
      task.cancel();
    }
    _activeTasks.clear();
  }

  /// Get active download task for a surah
  DownloadTask? getDownloadTask(int surahId) {
    return _activeTasks[surahId];
  }

  /// Check if a surah is currently downloading
  bool isDownloading(int surahId) {
    if (_activeTasks.containsKey(surahId)) {
      return _activeTasks[surahId]!.status == DownloadStatus.downloading;
    }
    return false;
  }

  /// Get all active downloads
  List<DownloadTask> getActiveDownloads() {
    return _activeTasks.values
        .where((task) => task.status == DownloadStatus.downloading)
        .toList();
  }

  /// Delete a downloaded surah
  Future<bool> deleteDownloadedSurah(SurahModel surah) async {
    try {
      final filePath = await getLocalFilePath(surah);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete all downloaded surahs
  Future<int> deleteAllDownloads() async {
    try {
      final audioDir = await getAudioDirectory();
      if (!await audioDir.exists()) return 0;

      int count = 0;
      await for (final entity in audioDir.list()) {
        if (entity is File) {
          await entity.delete();
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Get list of downloaded surah IDs
  Future<List<int>> getDownloadedSurahIds() async {
    try {
      final audioDir = await getAudioDirectory();
      if (!await audioDir.exists()) return [];

      final List<int> ids = [];
      await for (final entity in audioDir.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final fileName = entity.uri.pathSegments.last;
          final idStr = fileName.replaceAll('.mp3', '');
          final id = int.tryParse(idStr);
          if (id != null) {
            ids.add(id);
          }
        }
      }
      return ids..sort();
    } catch (e) {
      return [];
    }
  }

  /// Verify integrity of downloaded file
  Future<bool> verifyDownloadedFile(SurahModel surah) async {
    try {
      final filePath = await getLocalFilePath(surah);
      final file = File(filePath);

      if (!await file.exists()) return false;

      // Check if file has reasonable size (at least 10KB)
      final size = await file.length();
      if (size < 10240) return false;

      // Optionally verify by checking remote file size
      final remoteSize = await getRemoteFileSize(surah.audioUrl);
      if (remoteSize != null) {
        // Allow 1% tolerance
        final tolerance = remoteSize * 0.01;
        return (size - remoteSize).abs() <= tolerance;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the service
  void dispose() {
    for (final task in _activeTasks.values) {
      task.dispose();
    }
    _activeTasks.clear();
    _eventController.close();
  }
}

/// Event class for download updates
class DownloadEvent {
  /// ID of the surah being downloaded
  final int surahId;

  /// Current download status
  final DownloadStatus status;

  /// Current download progress (0.0 to 1.0)
  final double progress;

  /// Bytes downloaded so far
  final int downloadedBytes;

  /// Total bytes to download
  final int totalBytes;

  /// Error message if failed
  final String? errorMessage;

  /// Constructor
  DownloadEvent({
    required this.surahId,
    required this.status,
    required this.progress,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  /// Check if download is complete
  bool get isComplete => status == DownloadStatus.completed;

  /// Check if download failed
  bool get isFailed => status == DownloadStatus.failed;

  /// Check if download was cancelled
  bool get isCancelled => status == DownloadStatus.cancelled;

  /// Check if download is in progress
  bool get isInProgress => status == DownloadStatus.downloading;

  /// Get progress percentage as string
  String get progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';

  /// Get download speed text
  String get downloadInfo {
    if (totalBytes > 0) {
      final downloaded = DownloadService().formatFileSize(downloadedBytes);
      final total = DownloadService().formatFileSize(totalBytes);
      return '$downloaded / $total';
    }
    return '';
  }

  @override
  String toString() {
    return 'DownloadEvent(surahId: $surahId, status: $status, progress: $progress)';
  }
}
