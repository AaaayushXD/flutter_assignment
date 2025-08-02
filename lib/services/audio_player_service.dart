import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song_model.dart';
import 'youtube_audio_service.dart';
import 'cached_audio_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final CachedAudioService _cachedAudioService = CachedAudioService();
  List<Song> _currentPlaylist = [];
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _autoProgressTriggered = false;

  // Getters
  AudioPlayer get player => _audioPlayer;
  List<Song> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isInitialized => _isInitialized;
  Song? get currentSong =>
      _currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length
      ? _currentPlaylist[_currentIndex]
      : null;

  // Initialize the audio player
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      // Listen to audio session interruptions
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Lower volume when interrupted
              _audioPlayer.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Pause when interrupted
              _audioPlayer.pause();
              break;
            default:
              // Handle any other cases
              _audioPlayer.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Restore volume
              _audioPlayer.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Resume playback
              _audioPlayer.play();
              break;
            default:
              // Handle any other cases
              break;
          }
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        print('Audio player state: ${state.processingState}');
      });

      // Listen to position changes for auto-progression
      _audioPlayer.positionStream.listen((position) {
        print('Audio position: ${position.inSeconds}s');

        // Check if we're near the end of the song for auto-progression
        final duration = _audioPlayer.duration;
        if (duration != null &&
            _currentPlaylist.length > 1 &&
            !_autoProgressTriggered) {
          final remaining = duration - position;
          // If less than 1 second remaining, trigger auto-progression
          if (remaining.inMilliseconds < 1000 && remaining.inMilliseconds > 0) {
            print('Near end of song, triggering auto-progression...');
            _autoProgressTriggered = true;
            _autoProgressToNext();
          }
        }
      });

      // Listen to player state changes for automatic progression (backup method)
      _audioPlayer.playerStateStream.listen((state) {
        print(
          'Audio player state: ${state.processingState}, playing: ${state.playing}',
        );

        // Auto-progress to next song when current song completes
        if (state.processingState == ProcessingState.completed) {
          print('Song completed (state method), auto-progression to next...');
          _autoProgressToNext();
        }
      });

      _isInitialized = true;
      print(
        'Audio player service initialized with background playback support',
      );
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  // Load a single song
  Future<void> loadSong(Song song) async {
    try {
      await initialize();

      // Check if the same song is already loaded
      if (_currentPlaylist.isNotEmpty &&
          _currentIndex < _currentPlaylist.length &&
          _currentPlaylist[_currentIndex].id == song.id) {
        print('Song already loaded: ${song.title}');
        return; // Don't reload the same song
      }

      String audioUrl;

      // Use progressive streaming: start playing immediately + background download
      if (song.youtubeUrl.contains('youtube.com') ||
          song.youtubeUrl.contains('youtu.be')) {
        audioUrl = await _cachedAudioService
            .getStreamingUrlWithBackgroundDownload(song);
      } else {
        // Assume it's already an audio URL
        audioUrl = song.youtubeUrl;
      }

      await _audioPlayer.setUrl(audioUrl);
      _currentPlaylist = [song];
      _currentIndex = 0;

      print('Loaded song with progressive streaming: ${song.title}');
    } catch (e) {
      print('Error loading song: $e');
      rethrow;
    }
  }

  // Load a playlist
  Future<void> loadPlaylist(List<Song> songs, {int startIndex = 0}) async {
    try {
      await initialize();

      if (songs.isEmpty) {
        print('No songs in playlist');
        return;
      }

      // Check if the same playlist is already loaded
      if (_currentPlaylist.length == songs.length &&
          startIndex < songs.length &&
          _currentIndex == startIndex) {
        bool samePlaylist = true;
        for (int i = 0; i < songs.length; i++) {
          if (_currentPlaylist[i].id != songs[i].id) {
            samePlaylist = false;
            break;
          }
        }
        if (samePlaylist) {
          print('Playlist already loaded with ${songs.length} songs');
          return; // Don't reload the same playlist
        }
      }

      _currentPlaylist = songs;
      _currentIndex = startIndex.clamp(0, songs.length - 1);

      // Load the first song using playlist method
      await _loadCurrentSongInPlaylist();

      // Start preloading the rest of the playlist in background
      _preloadPlaylistInBackground(songs);

      print('Loaded playlist with ${songs.length} songs');
    } catch (e) {
      print('Error loading playlist: $e');
      rethrow;
    }
  }

  // Preload playlist in background for faster playback
  Future<void> _preloadPlaylistInBackground(List<Song> songs) async {
    try {
      // Skip the first song since it's already loaded
      final songsToPreload = songs.skip(1).toList();
      if (songsToPreload.isNotEmpty) {
        print('Starting background preload for ${songsToPreload.length} songs');
        _cachedAudioService.preloadPlaylist(songsToPreload);
      }
    } catch (e) {
      print('Error preloading playlist: $e');
    }
  }

  // Play current song
  Future<void> play() async {
    try {
      await _audioPlayer.play();
      print('Playing: ${currentSong?.title}');
    } catch (e) {
      print('Error playing: $e');
      rethrow;
    }
  }

  // Pause current song
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      print('Paused: ${currentSong?.title}');
    } catch (e) {
      print('Error pausing: $e');
      rethrow;
    }
  }

  // Stop current song
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      print('Stopped: ${currentSong?.title}');
    } catch (e) {
      print('Error stopping: $e');
      rethrow;
    }
  }

  // Play next song in playlist
  Future<void> next() async {
    if (_currentPlaylist.isEmpty) {
      print('No songs in playlist');
      return;
    }

    try {
      // Loop around to first song if at the end
      if (_currentIndex >= _currentPlaylist.length - 1) {
        _currentIndex = 0; // Loop to first song
        print('Reached end of playlist, looping to first song');
      } else {
        _currentIndex++; // Move to next song
      }

      await _loadCurrentSongInPlaylist();
      await play();
      print('Playing next: ${currentSong?.title}');
    } catch (e) {
      print('Error playing next: $e');
      rethrow;
    }
  }

  // Play previous song in playlist
  Future<void> previous() async {
    if (_currentPlaylist.isEmpty || _currentIndex <= 0) {
      print('No previous song available');
      return;
    }

    try {
      _currentIndex--;
      await _loadCurrentSongInPlaylist();
      await play();
      print('Playing previous: ${currentSong?.title}');
    } catch (e) {
      print('Error playing previous: $e');
      rethrow;
    }
  }

  // Load the current song in playlist without resetting the playlist
  Future<void> _loadCurrentSongInPlaylist() async {
    if (_currentPlaylist.isEmpty || _currentIndex >= _currentPlaylist.length) {
      throw Exception('Invalid playlist state');
    }

    final song = _currentPlaylist[_currentIndex];
    String audioUrl;

    // Use progressive streaming for playlist songs too
    if (song.youtubeUrl.contains('youtube.com') ||
        song.youtubeUrl.contains('youtu.be')) {
      audioUrl = await _cachedAudioService
          .getStreamingUrlWithBackgroundDownload(song);
    } else {
      // Assume it's already an audio URL
      audioUrl = song.youtubeUrl;
    }

    await _audioPlayer.setUrl(audioUrl);
    _autoProgressTriggered = false; // Reset flag for new song
    print('Loaded song in playlist with progressive streaming: ${song.title}');
  }

  // Auto-progress to next song when current song completes
  Future<void> _autoProgressToNext() async {
    print(
      'Auto-progression triggered. Playlist length: ${_currentPlaylist.length}, current index: $_currentIndex',
    );

    if (_currentPlaylist.isEmpty) {
      print('No songs in playlist, stopping playback');
      await stop();
      return;
    }

    try {
      // Loop around to first song if at the end
      if (_currentIndex >= _currentPlaylist.length - 1) {
        _currentIndex = 0; // Loop to first song
        print('Reached end of playlist, looping to first song');
      } else {
        _currentIndex++; // Move to next song
        print('Moving to next song at index: $_currentIndex');
      }

      await _loadCurrentSongInPlaylist();
      await play();
      print('Auto-progressed to song: ${currentSong?.title}');
    } catch (e) {
      print('Error auto-progressing to next song: $e');
      // If auto-progression fails, stop playback
      await stop();
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
      rethrow;
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting volume: $e');
      rethrow;
    }
  }

  // Get current position
  Duration get position => _audioPlayer.position;

  // Get total duration
  Duration? get duration => _audioPlayer.duration;

  // Get playback state
  PlayerState get playerState => _audioPlayer.playerState;

  // Check if playing
  bool get isPlaying => _audioPlayer.playing;

  // Check if paused
  bool get isPaused =>
      !_audioPlayer.playing &&
      _audioPlayer.playerState.processingState == ProcessingState.ready;

  // Check if stopped
  bool get isStopped =>
      _audioPlayer.playerState.processingState == ProcessingState.idle;

  // Check if audio is currently playing (for mini player visibility)
  bool get hasActiveAudio =>
      _audioPlayer.playerState.processingState != ProcessingState.idle &&
      _currentPlaylist.isNotEmpty;

  // Check if a specific song is currently loaded
  bool isSongLoaded(Song song) {
    return _currentPlaylist.isNotEmpty &&
        _currentIndex < _currentPlaylist.length &&
        _currentPlaylist[_currentIndex].id == song.id;
  }

  // Cache management methods
  Future<void> clearCache() async {
    await _cachedAudioService.clearCache();
  }

  Future<int> getCacheSize() async {
    return await _cachedAudioService.getCacheSize();
  }

  Future<bool> isSongCached(Song song) async {
    return await _cachedAudioService.isSongCached(song);
  }

  Future<String> getCacheInfo() async {
    return await _cachedAudioService.getCacheInfo();
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _currentPlaylist.clear();
      _currentIndex = 0;
      _isInitialized = false;
      print('Audio player service disposed');
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }
}
