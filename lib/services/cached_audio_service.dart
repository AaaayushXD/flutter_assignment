import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import 'youtube_audio_service.dart';

class CachedAudioService {
  static final CachedAudioService _instance = CachedAudioService._internal();
  factory CachedAudioService() => _instance;
  CachedAudioService._internal();

  late Dio _dio;
  late Directory _cacheDir;
  final YouTubeAudioService _youtubeService = YouTubeAudioService();

  // Cache configuration
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB

  Future<void> initialize() async {
    // Setup cache directory (internal storage, no permissions needed)
    _cacheDir = await _getCacheDirectory();

    // Setup Dio for downloads
    _dio = Dio();

    // Try to request permissions for external storage (optional)
    _requestPermissions().catchError((e) {
      print('Permission request failed: $e');
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Try different permission types based on Android version
      PermissionStatus status;

      if (await Permission.storage.isDenied) {
        status = await Permission.storage.request();
      } else if (await Permission.manageExternalStorage.isDenied) {
        status = await Permission.manageExternalStorage.request();
      } else {
        // For newer Android versions, we'll use app's internal storage
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        print('Storage permission not granted, using internal storage only');
      }
    }
  }

  Future<Directory> _getCacheDirectory() async {
    // Use app's internal documents directory (no permissions needed)
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    print('Cache directory: ${cacheDir.path}');
    return cacheDir;
  }

  Future<String?> getCachedAudioUrl(Song song) async {
    try {
      await initialize();

      // Check if audio is already cached
      final cachedPath = await _getCachedFilePath(song);
      if (await File(cachedPath).exists()) {
        print('Using cached audio for: ${song.title}');
        return cachedPath;
      }

      // Return null to trigger streaming + background download
      return null;
    } catch (e) {
      print('Error getting cached audio: $e');
      return null;
    }
  }

  // New method: Get streaming URL and start background download
  Future<String> getStreamingUrlWithBackgroundDownload(Song song) async {
    try {
      await initialize();

      // Check if already cached
      final cachedPath = await _getCachedFilePath(song);
      if (await File(cachedPath).exists()) {
        print('Using cached audio for: ${song.title}');
        return cachedPath;
      }

      // Get streaming URL for immediate playback
      final audioUrl = await _youtubeService.convertToAudioUrl(song.youtubeUrl);
      if (audioUrl == null) {
        throw Exception('Failed to get audio URL for streaming');
      }

      // Start background download for future use
      _downloadAndCacheAudioInBackground(song, audioUrl);

      print('Streaming audio for: ${song.title} (background download started)');
      return audioUrl;
    } catch (e) {
      print('Error getting streaming URL: $e');
      rethrow;
    }
  }

  Future<String> _getCachedFilePath(Song song) async {
    final videoId = _youtubeService.extractVideoId(song.youtubeUrl);
    final fileName = '${videoId}_${song.id}.mp3';
    return '${_cacheDir.path}/$fileName';
  }

  // Background download method
  Future<void> _downloadAndCacheAudioInBackground(
    Song song,
    String audioUrl,
  ) async {
    try {
      print('Starting background download for: ${song.title}');

      final cachedPath = await _getCachedFilePath(song);

      // Check if already downloaded while we were waiting
      if (await File(cachedPath).exists()) {
        print('Song already cached during background download: ${song.title}');
        return;
      }

      await _downloadFile(audioUrl, cachedPath);

      // Clean up old cache if needed
      await _cleanupCache();

      print('Successfully cached audio in background: ${song.title}');
    } catch (e) {
      print('Error downloading audio in background: ${song.title}, error: $e');
    }
  }

  Future<String?> _downloadAndCacheAudio(Song song) async {
    try {
      print('Downloading audio for: ${song.title}');

      // Get audio URL from YouTube
      final audioUrl = await _youtubeService.convertToAudioUrl(song.youtubeUrl);
      if (audioUrl == null) {
        throw Exception('Failed to get audio URL');
      }

      // Download audio file
      final cachedPath = await _getCachedFilePath(song);
      await _downloadFile(audioUrl, cachedPath);

      // Clean up old cache if needed
      await _cleanupCache();

      print('Successfully cached audio for: ${song.title}');
      return cachedPath;
    } catch (e) {
      print('Error downloading audio: $e');
      return null;
    }
  }

  Future<void> _downloadFile(String url, String filePath) async {
    try {
      final response = await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // Delete partial file if download failed
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<void> _cleanupCache() async {
    try {
      final files = _cacheDir.listSync();
      int totalSize = 0;

      // Calculate total cache size
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      // If cache is too large, remove oldest files
      if (totalSize > _maxCacheSize) {
        final sortedFiles = files.whereType<File>().toList()
          ..sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
          );

        for (final file in sortedFiles) {
          await file.delete();
          totalSize -= await file.length();
          if (totalSize <= _maxCacheSize * 0.8) break; // Keep 80% of max size
        }
      }
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  Future<void> preloadPlaylist(List<Song> songs) async {
    try {
      print('Starting playlist preload for ${songs.length} songs');

      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        print('Preloading song ${i + 1}/${songs.length}: ${song.title}');

        // Check if already cached
        final cachedPath = await _getCachedFilePath(song);
        if (await File(cachedPath).exists()) {
          print('Song already cached: ${song.title}');
          continue;
        }

        // Download in background
        _downloadAndCacheAudio(song).catchError((e) {
          print('Failed to preload song: ${song.title}, error: $e');
        });

        // Small delay to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error preloading playlist: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final files = _cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final files = _cacheDir.listSync();
      int totalSize = 0;

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  Future<bool> isSongCached(Song song) async {
    try {
      final cachedPath = await _getCachedFilePath(song);
      return await File(cachedPath).exists();
    } catch (e) {
      return false;
    }
  }

  Future<String> getCacheInfo() async {
    try {
      final size = await getCacheSize();
      final files = _cacheDir.listSync();
      final fileCount = files.whereType<File>().length;

      return 'Cache: ${(size / 1024 / 1024).toStringAsFixed(1)}MB, $fileCount files';
    } catch (e) {
      return 'Cache: Error getting info';
    }
  }
}
