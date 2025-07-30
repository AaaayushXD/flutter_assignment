import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';

class PlaylistVinylPlayer extends StatefulWidget {
  final Playlist playlist;
  final List<Song> songs;

  const PlaylistVinylPlayer({
    super.key,
    required this.playlist,
    required this.songs,
  });

  @override
  State<PlaylistVinylPlayer> createState() => _PlaylistVinylPlayerState();
}

class _PlaylistVinylPlayerState extends State<PlaylistVinylPlayer>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioService = AudioPlayerService();

  // Animation Controllers
  AnimationController? _vinylRotationController;
  AnimationController? _needleController;
  AnimationController? _dropAnimationController;

  // Animations
  Animation<double>? _vinylRotation;
  Animation<double>? _needleAnimation;
  Animation<double>? _dropAnimation;

  // State variables
  bool _animationsInitialized = false;
  bool _needleDropped = false;
  double _needleAngle = 1.2; // Start angle (same as audio player)
  final double _needleLength = 150.0;
  bool _isShuffled = false;
  int _currentSongIndex = 0;
  List<Song> _currentPlaylist = [];
  bool _isPreloading = false;

  // Needle positioning - exact same as working audio player
  late Offset _vinylCenter;
  late Offset _needlePivot;
  final double restAngle = 1.2; // Resting position angle (same as audio player)
  final double playAngle = 2.1; // Playing position angle (same as audio player)

  @override
  void initState() {
    super.initState();
    _currentPlaylist = List.from(widget.songs);
    _initializePositions();
    _initializeAnimations();
    _initializePlaylist();
    _syncWithAudioService();
  }

  void _initializePositions() {
    // Use exact same positions as working audio player
    _vinylCenter = const Offset(
      200,
      250,
    ); // Center of vinyl disc (same as audio player)
    _needlePivot = const Offset(
      320,
      150,
    ); // Fixed pivot point (same as audio player)
  }

  Future<void> _initializePlaylist() async {
    if (_currentPlaylist.isNotEmpty) {
      try {
        await _audioService.loadPlaylist(
          _currentPlaylist,
          startIndex: _currentSongIndex,
        );
        _preloadNextSong();
      } catch (e) {
        print('Error initializing playlist: $e');
      }
    }
  }

  void _initializeAnimations() {
    try {
      // Vinyl rotation controller (continuous)
      _vinylRotationController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );

      // Needle drop controller
      _needleController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      // Drop animation controller
      _dropAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      // Create animations
      _vinylRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(
          parent: _vinylRotationController!,
          curve: Curves.linear,
        ),
      );

      _needleAnimation = Tween<double>(begin: restAngle, end: playAngle)
          .animate(
            CurvedAnimation(
              parent: _needleController!,
              curve: Curves.easeInOut,
            ),
          );

      _dropAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _dropAnimationController!,
          curve: Curves.elasticOut,
        ),
      );

      // Listen to needle animation changes
      _needleAnimation!.addListener(() {
        setState(() {
          _needleAngle = _needleAnimation!.value;
        });
      });

      setState(() {
        _animationsInitialized = true;
      });
    } catch (e) {
      print('Error initializing animations: $e');
    }
  }

  void _syncWithAudioService() {
    _audioService.player.playerStateStream.listen((state) {
      if (mounted) {
        final isPlaying = state.playing;
        setState(() {
          _needleDropped = isPlaying;
          if (isPlaying) {
            _needleAngle = playAngle; // Play position
          } else {
            _needleAngle = restAngle; // Rest position
          }
        });
        _updateVinylRotation();
      }
    });

    // Listen for song completion to auto-play next
    _audioService.player.playerStateStream.listen((state) {
      if (state.processingState.name == 'completed') {
        _playNextSong();
      }
    });
  }

  void _updateVinylRotation() {
    if (_vinylRotationController != null) {
      if (_needleDropped) {
        _vinylRotationController!.repeat();
      } else {
        _vinylRotationController!.stop();
      }
    }
  }

  void _playNextSong() async {
    if (_currentPlaylist.isNotEmpty) {
      try {
        // Use AudioPlayerService's built-in next() for smooth transitions
        await _audioService.next();
        setState(() {
          _currentSongIndex = _audioService.currentIndex;
        });
        _preloadNextSong();
      } catch (e) {
        print('Error playing next song: $e');
      }
    }
  }

  void _playPreviousSong() async {
    if (_currentPlaylist.isNotEmpty) {
      try {
        // Use AudioPlayerService's built-in previous() for smooth transitions
        await _audioService.previous();
        setState(() {
          _currentSongIndex = _audioService.currentIndex;
        });
        _preloadNextSong();
      } catch (e) {
        print('Error playing previous song: $e');
      }
    }
  }

  void _playCurrentSong() async {
    if (_currentPlaylist.isNotEmpty &&
        _currentSongIndex < _currentPlaylist.length) {
      try {
        await _audioService.play();
        _preloadNextSong();
      } catch (e) {
        print('Error playing current song: $e');
        // Auto-skip to next song if current fails
        _playNextSong();
      }
    }
  }

  Future<void> _preloadNextSong() async {
    if (_isPreloading || _currentPlaylist.isEmpty) return;

    setState(() {
      _isPreloading = true;
    });

    try {
      final nextIndex = (_currentSongIndex + 1) % _currentPlaylist.length;
      final nextSong = _currentPlaylist[nextIndex];

      // Preload completed
      print('Preloaded next song: ${nextSong.title}');
    } catch (e) {
      print('Error preloading next song: $e');
    } finally {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        // Shuffle the playlist
        final currentSong = _currentPlaylist[_currentSongIndex];
        _currentPlaylist.shuffle();
        // Find the current song in shuffled list
        _currentSongIndex = _currentPlaylist.indexOf(currentSong);
      } else {
        // Restore original order
        _currentPlaylist = List.from(widget.songs);
        // Find current song in original list
        final currentSong = _audioService.currentSong;
        if (currentSong != null) {
          _currentSongIndex = _currentPlaylist.indexWhere(
            (s) => s.id == currentSong.id,
          );
        }
      }
    });
  }

  // Calculate needle tip position based on angle
  Offset _getNeedleTipPosition() {
    return Offset(
      _needlePivot.dx + math.cos(_needleAngle) * _needleLength,
      _needlePivot.dy + math.sin(_needleAngle) * _needleLength,
    );
  }

  // Check if needle is over vinyl center
  bool _isNeedleOnVinyl() {
    final tipPosition = _getNeedleTipPosition();
    final distanceToCenter = (tipPosition - _vinylCenter).distance;
    final centerRadius = 90.0; // Radius of center thumbnail area
    return distanceToCenter <= centerRadius;
  }

  void _onNeedlePan(DragUpdateDetails details) {
    if (!_animationsInitialized) return;

    // Convert pan delta to angle change
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);

      // Calculate angle from pivot to current touch position
      final dx = localPosition.dx - _needlePivot.dx;
      final dy = localPosition.dy - _needlePivot.dy;
      final newAngle = math.atan2(dy, dx);

      // Constrain angle to natural needle movement range (same as audio player)
      // From rest position (1.2 rad) to play position (2.1 rad) - allow reaching center
      final constrainedAngle = math.max(1.0, math.min(2.3, newAngle));

      setState(() {
        _needleAngle = constrainedAngle;
      });

      // Check if needle tip is over the center thumbnail area (same logic as audio player)
      final tipPosition = _getNeedleTipPosition();
      final distanceToCenter = (tipPosition - _vinylCenter).distance;
      final centerRadius =
          90.0; // Radius of center thumbnail area (same as audio player)

      final onCenter = distanceToCenter <= centerRadius;

      if (onCenter && !_needleDropped) {
        _dropNeedle();
      } else if (!onCenter && _needleDropped) {
        _liftNeedle();
      }
    }
  }

  void _onNeedlePanEnd(DragEndDetails details) {
    // Check if needle is over center thumbnail (same logic as audio player)
    final tipPosition = _getNeedleTipPosition();
    final distanceToCenter = (tipPosition - _vinylCenter).distance;
    final centerRadius =
        90.0; // Radius of center thumbnail area (same as audio player)

    final onCenter = distanceToCenter <= centerRadius;

    // If needle is not on center, return it to rest position (same as audio player)
    if (!onCenter) {
      if (_needleController != null) {
        _needleController!.reverse();
      }
      setState(() {
        _needleAngle = restAngle;
        _needleDropped = false;
      });
      _audioService.pause();
    }
  }

  void _dropNeedle() {
    if (_needleController == null) return;

    setState(() {
      _needleDropped = true;
    });
    _playCurrentSong();
  }

  void _liftNeedle() {
    if (_needleController == null) return;

    setState(() {
      _needleDropped = false;
    });
    _audioService.pause();
  }

  String _getPlaylistImageUrl() {
    if (widget.playlist.imageUrl != null &&
        widget.playlist.imageUrl!.isNotEmpty) {
      return widget.playlist.imageUrl!;
    }
    // Return a default music vinyl image
    return 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop';
  }

  String _getCurrentSongTitle() {
    if (_currentPlaylist.isNotEmpty &&
        _currentSongIndex < _currentPlaylist.length) {
      return _currentPlaylist[_currentSongIndex].title;
    }
    return 'No song selected';
  }

  @override
  void dispose() {
    _vinylRotationController?.dispose();
    _needleController?.dispose();
    _dropAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animationsInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          // Shuffle button
          IconButton(
            onPressed: _toggleShuffle,
            icon: Icon(
              Icons.shuffle,
              color: _isShuffled ? Colors.amber : Colors.white,
            ),
            tooltip: _isShuffled ? 'Shuffle On' : 'Shuffle Off',
          ),
          // Previous song
          IconButton(
            onPressed: _playPreviousSong,
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Previous Song',
          ),
          // Next song
          IconButton(
            onPressed: _playNextSong,
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Song',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _vinylRotation!,
          _needleAnimation!,
          _dropAnimation!,
        ]),
        builder: (context, child) {
          return Column(
            children: [
              // Current Song Info - Compact
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getCurrentSongTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPreloading)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        Text(
                          '${_currentSongIndex + 1}/${_currentPlaylist.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vinyl Player - Centered and Responsive
              Expanded(
                child: Center(
                  child: Container(
                    width: 400,
                    height: 400,
                    child: Stack(
                      children: [
                        // Vinyl Player Base
                        Center(
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3a3a3a),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Rotating Vinyl Disc
                        Center(
                          child: Transform.rotate(
                            angle: _vinylRotation!.value,
                            child: Container(
                              width: 360,
                              height: 360,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1a1a1a),
                                border: Border.all(
                                  color: const Color(0xFF4a4a4a),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Vinyl grooves
                                  ...List.generate(10, (index) {
                                    return Container(
                                      width: 360 - (index * 18),
                                      height: 360 - (index * 18),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2a2a2a),
                                          width: 1,
                                        ),
                                      ),
                                    );
                                  }),

                                  // Center with playlist image
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF4a4a4a),
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        _getPlaylistImageUrl(),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.playlist_play,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),

                                  // Center hole
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF1a1a1a),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Progress Ring
                        Center(
                          child: StreamBuilder<Duration>(
                            stream: _audioService.player.positionStream,
                            builder: (context, positionSnapshot) {
                              return StreamBuilder<Duration?>(
                                stream: _audioService.player.durationStream,
                                builder: (context, durationSnapshot) {
                                  final position =
                                      positionSnapshot.data ?? Duration.zero;
                                  final duration =
                                      durationSnapshot.data ?? Duration.zero;
                                  final progress = duration.inMilliseconds > 0
                                      ? position.inMilliseconds /
                                            duration.inMilliseconds
                                      : 0.0;

                                  return StreamBuilder(
                                    stream:
                                        _audioService.player.playerStateStream,
                                    builder: (context, stateSnapshot) {
                                      final isPlaying =
                                          stateSnapshot.data?.playing ?? false;

                                      return SizedBox(
                                        width: 420,
                                        height: 420,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 4,
                                          backgroundColor: Colors.grey[700],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                isPlaying
                                                    ? Colors.amber
                                                    : Colors.grey[600]!,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Needle Arm (exact same positioning as audio player)
                        Positioned(
                          left: _needlePivot.dx - 100,
                          top: _needlePivot.dy - 100,
                          width: 400,
                          height: 400,
                          child: GestureDetector(
                            onPanUpdate: _onNeedlePan,
                            onPanEnd: _onNeedlePanEnd,
                            child: CustomPaint(
                              painter: NeedlePainter(
                                pivotPoint: const Offset(
                                  100,
                                  100,
                                ), // Local coordinates within 400x400 area
                                angle: _needleAngle,
                                length: _needleLength,
                                isOnVinyl: _isNeedleOnVinyl(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Controls - Compact
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isShuffled)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shuffle, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Shuffle Mode On',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (_isShuffled) const SizedBox(height: 8),
                    Text(
                      'Drag the needle to the center to play',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom Painter for Needle - Fixed version
class NeedlePainter extends CustomPainter {
  final Offset pivotPoint;
  final double angle;
  final double length;
  final bool isOnVinyl;

  NeedlePainter({
    required this.pivotPoint,
    required this.angle,
    required this.length,
    required this.isOnVinyl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final handlePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    final pivotPaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.fill;

    final needleTipPaint = Paint()
      ..color = isOnVinyl ? Colors.red : const Color(0xFFC0C0C0)
      ..style = PaintingStyle.fill;

    // Calculate needle end position
    final endPoint = Offset(
      pivotPoint.dx + math.cos(angle) * length,
      pivotPoint.dy + math.sin(angle) * length,
    );

    // Draw needle arm
    canvas.drawLine(pivotPoint, endPoint, paint);

    // Draw pivot point
    canvas.drawCircle(pivotPoint, 12, pivotPaint);

    // Draw needle tip
    canvas.drawCircle(endPoint, 8, needleTipPaint);

    // Draw handle at pivot
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pivotPoint.dx, pivotPoint.dy - 20),
        width: 40,
        height: 20,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(handleRect, handlePaint);

    // Draw handle icon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '⚬',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(pivotPoint.dx - 8, pivotPoint.dy - 28));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
