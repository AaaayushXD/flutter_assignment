import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import 'audio_player_widget.dart';

class MiniPlayerWidget extends StatefulWidget {
  const MiniPlayerWidget({super.key});

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
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
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  void _openFullPlayer() {
    final currentSong = _audioService.currentSong;
    if (currentSong != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerWidget(
            song: currentSong,
            playlist: _audioService.currentPlaylist.length > 1
                ? _audioService.currentPlaylist
                : null,
            startIndex: _audioService.currentIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = _audioService.currentSong;

    // Debug information
    print(
      'MiniPlayer: hasActiveAudio=${_audioService.hasActiveAudio}, currentSong=${currentSong?.title}, height=100',
    );

    // Don't show mini player if no song is loaded or player is idle
    if (!_audioService.hasActiveAudio || currentSong == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar at the top
        if (_duration != null)
          LinearProgressIndicator(
            value: _duration!.inMilliseconds > 0
                ? _position.inMilliseconds / _duration!.inMilliseconds
                : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        // Main mini player content
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D2D2D)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: currentSong.thumbnailUrlGenerated.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              currentSong.thumbnailUrlGenerated,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Song Info
                  Expanded(
                    child: Text(
                      currentSong.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Controls
                  Row(
                    children: [
                      // Previous button (only if playlist has multiple songs)
                      if (_audioService.currentPlaylist.length > 1)
                        IconButton(
                          onPressed: _audioService.previous,
                          icon: const Icon(Icons.skip_previous, size: 24),
                          color: Colors.grey[700],
                        ),

                      // Play/Pause button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isPlaying
                              ? _audioService.pause
                              : _audioService.play,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 24,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),

                      // Next button (only if playlist has multiple songs)
                      if (_audioService.currentPlaylist.length > 1)
                        IconButton(
                          onPressed: _audioService.next,
                          icon: const Icon(Icons.skip_next, size: 24),
                          color: Colors.grey[700],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
