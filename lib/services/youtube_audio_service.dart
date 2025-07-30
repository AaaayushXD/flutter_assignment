import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioService {
  static final YouTubeAudioService _instance = YouTubeAudioService._internal();
  factory YouTubeAudioService() => _instance;
  YouTubeAudioService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  // Extract video ID from YouTube URL
  String extractVideoId(String youtubeUrl) {
    String videoId = '';

    if (youtubeUrl.contains('youtube.com/watch?v=')) {
      videoId = youtubeUrl.split('v=')[1];
      if (videoId.contains('&')) {
        videoId = videoId.split('&')[0];
      }
    } else if (youtubeUrl.contains('youtu.be/')) {
      videoId = youtubeUrl.split('youtu.be/')[1];
      if (videoId.contains('?')) {
        videoId = videoId.split('?')[0];
      }
    }

    return videoId;
  }

  // Get video info from YouTube using youtube_explode_dart
  Future<Map<String, dynamic>?> getVideoInfo(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);

      return {
        'title': video.title,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'videoId': videoId,
        'duration': video.duration,
        'author': video.author,
        'description': video.description,
      };
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  // Convert YouTube URL to a playable audio URL using youtube_explode_dart
  Future<String?> convertToAudioUrl(String youtubeUrl) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId.isEmpty) {
        throw Exception('Invalid YouTube URL: $youtubeUrl');
      }

      print('Converting YouTube URL: $youtubeUrl');
      print('Video ID: $videoId');

      // Get video manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Get audio-only streams, sorted by bitrate (highest first)
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      if (audioStreams.isEmpty) {
        throw Exception('No audio streams found for video: $videoId');
      }

      // Get the best quality audio stream
      final bestAudioStream = audioStreams.first;
      final audioUrl = bestAudioStream.url.toString();

      print(
        'Found audio stream: ${bestAudioStream.audioCodec} at ${bestAudioStream.bitrate}bps',
      );

      return audioUrl;
    } catch (e) {
      print('Error converting YouTube URL: $e');
      return null;
    }
  }

  // Get available audio formats for a video
  Future<List<Map<String, dynamic>>> getAudioFormats(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      return audioStreams
          .map(
            (stream) => {
              'format': stream.audioCodec,
              'quality': '${stream.bitrate}bps',
              'url': stream.url.toString(),
              'size': stream.size.totalBytes,
            },
          )
          .toList();
    } catch (e) {
      print('Error getting audio formats: $e');
      return [];
    }
  }

  // Check if a URL is a valid YouTube URL
  bool isValidYouTubeUrl(String url) {
    return url.contains('youtube.com/watch?v=') || url.contains('youtu.be/');
  }

  // Get video details including thumbnail
  Future<Map<String, dynamic>?> getVideoDetails(String youtubeUrl) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId.isEmpty) return null;

      final video = await _yt.videos.get(videoId);

      return {
        'title': video.title,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'videoId': videoId,
        'duration': video.duration,
        'author': video.author,
        'description': video.description,
        'uploadDate': video.uploadDate,
        'viewCount': video.engagement.viewCount,
      };
    } catch (e) {
      print('Error getting video details: $e');
      return null;
    }
  }

  // Get enhanced song details from YouTube
  Future<Map<String, dynamic>?> getEnhancedSongDetails(
    String youtubeUrl,
  ) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId.isEmpty) return null;

      final video = await _yt.videos.get(videoId);

      return {
        'title': video.title,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'videoId': videoId,
        'duration': video.duration,
        'author': video.author,
        'description': video.description,
        'uploadDate': video.uploadDate,
        'viewCount': video.engagement.viewCount,
        'likeCount': video.engagement.likeCount,
      };
    } catch (e) {
      print('Error getting enhanced song details: $e');
      return null;
    }
  }

  // Validate YouTube URL and get basic info
  Future<bool> isValidYouTubeVideo(String youtubeUrl) async {
    try {
      final videoId = extractVideoId(youtubeUrl);
      if (videoId.isEmpty) return false;

      // Try to get video info to validate
      await _yt.videos.get(videoId);
      return true;
    } catch (e) {
      print('Invalid YouTube video: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _yt.close();
  }
}
