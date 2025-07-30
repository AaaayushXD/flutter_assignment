import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Song song;
  final List<Song>? playlist;
  final int? startIndex;

  const AudioPlayerWidget({
    super.key,
    required this.song,
    this.playlist,
    this.startIndex,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if the song is already loaded to prevent unnecessary reloading
      if (widget.playlist != null) {
        await _audioService.loadPlaylist(
          widget.playlist!,
          startIndex: widget.startIndex ?? 0,
        );
      } else {
        // Only load if not already loaded
        if (!_audioService.isSongLoaded(widget.song)) {
          await _audioService.loadSong(widget.song);
        }
      }

      // Listen to player state changes
      _audioService.player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      // Listen to position changes
      _audioService.player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen to duration changes
      _audioService.player.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Sync current state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = _audioService.isPlaying;
          _position = _audioService.position;
          _duration = _audioService.duration;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        String errorMessage = 'Error loading audio: $e';

        // Provide more specific error messages for YouTube URLs
        if (e.toString().contains('Failed to extract audio from YouTube')) {
          errorMessage =
              'Failed to extract audio from YouTube video. '
              'The video might be private, restricted, or unavailable.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_audioService.currentSong?.title ?? widget.song.title),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Song Info
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Thumbnail
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            _audioService
                                    .currentSong
                                    ?.thumbnailUrlGenerated
                                    .isNotEmpty ==
                                true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _audioService
                                      .currentSong!
                                      .thumbnailUrlGenerated,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.music_note,
                                      size: 60,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        _audioService.currentSong?.title ?? widget.song.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Artist/User
                      Text(
                        'Added by ${_audioService.currentSong?.userName ?? widget.song.userName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0,
                        max: _duration?.inSeconds.toDouble() ?? 0,
                        onChanged: (value) {
                          _audioService.seek(Duration(seconds: value.toInt()));
                        },
                        activeColor: Colors.purple,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position)),
                            Text(
                              _duration != null
                                  ? _formatDuration(_duration!)
                                  : '--:--',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous
                    IconButton(
                      onPressed: widget.playlist != null
                          ? _audioService.previous
                          : null,
                      icon: const Icon(Icons.skip_previous, size: 40),
                      color: Colors.purple,
                    ),

                    // Play/Pause
                    IconButton(
                      onPressed: _isPlaying
                          ? _audioService.pause
                          : _audioService.play,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 50,
                      ),
                      color: Colors.purple,
                    ),

                    // Next
                    IconButton(
                      onPressed: widget.playlist != null
                          ? _audioService.next
                          : null,
                      icon: const Icon(Icons.skip_next, size: 40),
                      color: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Volume Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                            _audioService.setVolume(value);
                          },
                          activeColor: Colors.purple,
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.grey),
                    ],
                  ),
                ),

                // Playlist Info (if available)
                if (widget.playlist != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Playlist: ${widget.playlist!.length} songs',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_audioService.currentIndex + 1} of ${widget.playlist!.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // YouTube info section (optional - can be removed if not needed)
                if (widget.song.youtubeUrl.contains('youtube.com') ||
                    widget.song.youtubeUrl.contains('youtu.be'))
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Playing audio from YouTube',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the audio service here as it's a singleton
    // Don't stop the audio when leaving the page - let it continue playing
    // The audio will continue playing in the background via the mini player
    super.dispose();
  }
}
