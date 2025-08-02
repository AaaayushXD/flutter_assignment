import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/audio_player_service.dart';
import '../providers/theme_provider.dart';
import 'global_theme_switcher.dart';

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
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _volume = 1.0;

  // Vinyl player specific animations
  AnimationController? _vinylRotationController;
  AnimationController? _needleController;
  Animation<double>? _vinylRotation;
  Animation<double>? _needleAnimation;

  // Vinyl player state
  bool _needleDropped = false;
  bool _animationsInitialized = false;

  // Needle positioning - exact same as working audio player
  late Offset _vinylCenter;
  late Offset _needlePivot;
  double _needleAngle = 1.2; // Start angle (radians) - needle resting position
  final double _needleLength = 150.0; // Length of the needle arm
  final double restAngle =
      1.2; // Resting position angle (pointing to vinyl edge, outside center)
  final double playAngle =
      2.1; // Playing position angle (pointing toward vinyl center)

  // Playlist state
  bool _isShuffled = false;
  int _currentSongIndex = 0;
  List<Song> _currentPlaylist = [];
  bool _isPreloading = false;
  bool _isBackgroundDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = List.from(widget.songs);
    _initializeAnimations();
    _initializePlayer();
    _syncWithAudioService();
  }

  void _syncWithAudioService() {
    // Listen to audio service state changes to maintain needle position and update current song
    _audioService.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _needleDropped = state.playing;
          if (state.playing) {
            _needleAngle = playAngle;
            if (_vinylRotationController != null &&
                !_vinylRotationController!.isAnimating) {
              _vinylRotationController!.repeat();
            }
          } else {
            _needleAngle = restAngle;
            _vinylRotationController?.stop();
          }

          // Update current index when song changes (for auto-progression)
          if (state.processingState == ProcessingState.ready) {
            _currentSongIndex = _audioService.currentIndex;
            // Check if current song is being downloaded in background
            _checkBackgroundDownloadStatus();
          }
        });
      }
    });
  }

  Future<void> _checkBackgroundDownloadStatus() async {
    if (_currentPlaylist.isNotEmpty &&
        _currentSongIndex < _currentPlaylist.length) {
      final currentSong = _currentPlaylist[_currentSongIndex];
      final isCached = await _audioService.isSongCached(currentSong);

      if (mounted) {
        setState(() {
          _isBackgroundDownloading = !isCached;
        });
      }
    }
  }

  void _initializeAnimations() {
    // Calculate positions based on screen layout - exact same as working audio player
    _vinylCenter = const Offset(200, 250); // Center of vinyl disc
    _needlePivot = const Offset(
      320,
      150,
    ); // Fixed pivot point on the upper right side

    // Vinyl rotation animation
    _vinylRotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _vinylRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _vinylRotationController!, curve: Curves.linear),
    );

    // Needle drop animation
    _needleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _needleAnimation = Tween<double>(begin: restAngle, end: playAngle).animate(
      CurvedAnimation(parent: _needleController!, curve: Curves.easeInOut),
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
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentPlaylist.isNotEmpty) {
        await _audioService.loadPlaylist(
          _currentPlaylist,
          startIndex: _currentSongIndex,
        );
        _preloadNextSong();
      }

      // Listen to player state changes
      _audioService.player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          _updateVinylRotation();
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
          _currentSongIndex = _audioService.currentIndex;
        });
        _updateVinylRotation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        String errorMessage = 'Error loading playlist: $e';

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

  void _updateVinylRotation() {
    if (_vinylRotationController != null) {
      if (_isPlaying) {
        _vinylRotationController!.repeat();
      } else {
        _vinylRotationController!.stop();
      }
    }
  }

  void _playNextSong() async {
    if (_currentPlaylist.isNotEmpty && mounted) {
      try {
        await _audioService.next();
        if (mounted) {
          setState(() {
            _currentSongIndex = _audioService.currentIndex;
          });
        }
        _preloadNextSong();
      } catch (e) {
        print('Error playing next song: $e');
        // If there's an error, try to move to the next song anyway
        if (mounted) {
          setState(() {
            _currentSongIndex =
                (_currentSongIndex + 1) % _currentPlaylist.length;
          });
        }
      }
    }
  }

  void _playPreviousSong() async {
    if (_currentPlaylist.isNotEmpty && mounted) {
      try {
        await _audioService.previous();
        if (mounted) {
          setState(() {
            _currentSongIndex = _audioService.currentIndex;
          });
        }
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
        if (mounted) {
          _playNextSong();
        }
      }
    }
  }

  Future<void> _preloadNextSong() async {
    if (_isPreloading || _currentPlaylist.isEmpty) return;

    if (mounted) {
      setState(() {
        _isPreloading = true;
      });
    }

    try {
      final nextIndex = (_currentSongIndex + 1) % _currentPlaylist.length;
      final nextSong = _currentPlaylist[nextIndex];

      // Preload completed
      print('Preloaded next song: ${nextSong.title}');
    } catch (e) {
      print('Error preloading next song: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
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

  // Check if needle is over vinyl
  bool _isNeedleOnVinyl() {
    final tipPosition = _getNeedleTipPosition();
    final distance = (tipPosition - _vinylCenter).distance;
    return distance <= 180.0; // Vinyl radius
  }

  void _onNeedlePan(DragUpdateDetails details) {
    // Convert pan delta to angle change
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);

      // Calculate angle from pivot to current touch position
      final dx = localPosition.dx - _needlePivot.dx;
      final dy = localPosition.dy - _needlePivot.dy;
      final newAngle = math.atan2(dy, dx);

      // Constrain angle to natural needle movement range
      // From rest position (1.2 rad) to play position (2.1 rad) - allow reaching center
      final constrainedAngle = math.max(1.0, math.min(2.3, newAngle));

      setState(() {
        _needleAngle = constrainedAngle;
      });

      // Check if needle tip is over the center thumbnail area
      final tipPosition = _getNeedleTipPosition();
      final distanceToCenter = (tipPosition - _vinylCenter).distance;
      final centerRadius =
          90.0; // Radius of center thumbnail area (made larger)

      final onCenter = distanceToCenter <= centerRadius;

      if (onCenter && !_needleDropped) {
        _dropNeedle();
      } else if (!onCenter && _needleDropped) {
        _liftNeedle();
      }
    }
  }

  void _onNeedlePanEnd(DragEndDetails details) {
    // Check if needle is over center thumbnail
    final tipPosition = _getNeedleTipPosition();
    final distanceToCenter = (tipPosition - _vinylCenter).distance;
    final centerRadius = 90.0; // Radius of center thumbnail area (made larger)

    final onCenter = distanceToCenter <= centerRadius;

    // If needle is not on center, return it to rest position
    if (!onCenter) {
      _needleController!.reverse();
      setState(() {
        _needleAngle = restAngle;
      });
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
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        if (!_animationsInitialized) {
          return Scaffold(
            backgroundColor: isDarkMode
                ? const Color(0xFF1a1a1a)
                : const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: Text(
                widget.playlist.name,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: isDarkMode
                  ? const Color(0xFF2d2d2d)
                  : Colors.purple,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                GlobalThemeSwitcher(
                  isDarkMode: isDarkMode,
                  onThemeChanged: () {
                    themeProvider.toggleTheme();
                  },
                  size: 32,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDarkMode
              ? const Color(0xFF1a1a1a)
              : const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(
              widget.playlist.name,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isDarkMode
                ? const Color(0xFF2d2d2d)
                : Colors.purple,
            foregroundColor: Colors.white,
            elevation: 0,
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
              GlobalThemeSwitcher(
                isDarkMode: isDarkMode,
                onThemeChanged: () {
                  themeProvider.toggleTheme();
                },
                size: 32,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                )
              : Stack(
                  children: [
                    // Main content
                    Column(
                      children: [
                        // Current Song Info - Compact
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.music_note,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getCurrentSongTitle(),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.amber,
                                            ),
                                      ),
                                    ),
                                  if (_isBackgroundDownloading)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.download,
                                        color: Colors.green,
                                        size: 12,
                                      ),
                                    ),
                                  Text(
                                    '${_currentSongIndex + 1}/${_currentPlaylist.length}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.6)
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Vinyl Player Section
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Vinyl Player with Progress Ring
                                StreamBuilder<Duration>(
                                  stream: _audioService.player.positionStream,
                                  builder: (context, positionSnapshot) {
                                    return StreamBuilder<Duration?>(
                                      stream:
                                          _audioService.player.durationStream,
                                      builder: (context, durationSnapshot) {
                                        return StreamBuilder<bool>(
                                          stream: _audioService
                                              .player
                                              .playerStateStream
                                              .map((state) => state.playing),
                                          builder: (context, playingSnapshot) {
                                            final position =
                                                positionSnapshot.data ??
                                                Duration.zero;
                                            final duration =
                                                durationSnapshot.data ??
                                                Duration.zero;
                                            final progress =
                                                duration.inMilliseconds > 0
                                                ? position.inMilliseconds /
                                                      duration.inMilliseconds
                                                : 0.0;
                                            final isPlaying =
                                                playingSnapshot.data ?? false;

                                            return SizedBox(
                                              width: 420,
                                              height: 420,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // Progress ring around vinyl
                                                  SizedBox(
                                                    width: 420,
                                                    height: 420,
                                                    child: CircularProgressIndicator(
                                                      value: progress,
                                                      strokeWidth: 10,
                                                      backgroundColor: Colors
                                                          .grey
                                                          .withOpacity(0.2),
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            isPlaying
                                                                ? Colors.amber
                                                                : Colors.grey
                                                                      .withOpacity(
                                                                        0.4,
                                                                      ),
                                                          ),
                                                    ),
                                                  ),
                                                  // Vinyl base
                                                  Container(
                                                    width: 400,
                                                    height: 400,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF3a3a3a,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            200,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          blurRadius: 20,
                                                          offset: const Offset(
                                                            0,
                                                            10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        // Vinyl Disc
                                                        if (_vinylRotation !=
                                                            null)
                                                          AnimatedBuilder(
                                                            animation:
                                                                _vinylRotation!,
                                                            builder: (context, child) {
                                                              return Transform.rotate(
                                                                angle:
                                                                    _needleDropped
                                                                    ? _vinylRotation!
                                                                          .value
                                                                    : 0,
                                                                child: Container(
                                                                  width: 360,
                                                                  height: 360,
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: const Color(
                                                                      0xFF1a1a1a,
                                                                    ),
                                                                    border: Border.all(
                                                                      color: const Color(
                                                                        0xFF4a4a4a,
                                                                      ),
                                                                      width: 2,
                                                                    ),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.3,
                                                                            ),
                                                                        blurRadius:
                                                                            10,
                                                                        offset:
                                                                            const Offset(
                                                                              0,
                                                                              5,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  child: Stack(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    children: [
                                                                      // Vinyl grooves
                                                                      ...List.generate(10, (
                                                                        index,
                                                                      ) {
                                                                        return Container(
                                                                          width:
                                                                              360 -
                                                                              (index *
                                                                                  18),
                                                                          height:
                                                                              360 -
                                                                              (index *
                                                                                  18),
                                                                          decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border: Border.all(
                                                                              color: const Color(
                                                                                0xFF2a2a2a,
                                                                              ),
                                                                              width: 1,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }),
                                                                      // Center label with playlist image
                                                                      Container(
                                                                        width:
                                                                            150,
                                                                        height:
                                                                            150,
                                                                        decoration: BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              Colors.white,
                                                                          border: Border.all(
                                                                            color: const Color(
                                                                              0xFF4a4a4a,
                                                                            ),
                                                                            width:
                                                                                3,
                                                                          ),
                                                                        ),
                                                                        child: ClipOval(
                                                                          child: Image.network(
                                                                            _getPlaylistImageUrl(),
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            errorBuilder:
                                                                                (
                                                                                  context,
                                                                                  error,
                                                                                  stackTrace,
                                                                                ) {
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
                                                                        width:
                                                                            25,
                                                                        height:
                                                                            25,
                                                                        decoration: const BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color: Color(
                                                                            0xFF1a1a1a,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 30),
                                // Song Info
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _getCurrentSongTitle(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Playlist: ${widget.playlist.name}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDarkMode
                                              ? Colors.grey
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Time display (compact)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _duration != null
                                    ? _formatDuration(_duration!)
                                    : '--:--',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Playback Controls
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Previous
                              IconButton(
                                onPressed: _playPreviousSong,
                                icon: const Icon(Icons.skip_previous, size: 40),
                                color: Colors.amber,
                              ),

                              // Volume Control
                              Row(
                                children: [
                                  Icon(
                                    Icons.volume_down,
                                    color: isDarkMode
                                        ? Colors.grey
                                        : Colors.black54,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.amber,
                                        inactiveTrackColor: isDarkMode 
                                            ? Colors.grey[600] 
                                            : Colors.grey[400],
                                        thumbColor: Colors.amber,
                                        overlayColor: Colors.amber.withOpacity(
                                          0.2,
                                        ),
                                      ),
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
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.volume_up,
                                    color: isDarkMode
                                        ? Colors.grey
                                        : Colors.black54,
                                  ),
                                ],
                              ),

                              // Next
                              IconButton(
                                onPressed: _playNextSong,
                                icon: const Icon(Icons.skip_next, size: 40),
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ),

                        // Playlist Info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Playlist: ${_currentPlaylist.length} songs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                '${_currentSongIndex + 1} of ${_currentPlaylist.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status indicators
                        if (_isShuffled || _isBackgroundDownloading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                if (_isShuffled)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shuffle,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
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
                                if (_isBackgroundDownloading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.download,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Downloading for offline use',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Improved Needle Arm
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
                            ), // Local coordinates within the 400x400 area
                            angle: _needleAngle,
                            length: _needleLength,
                            isOnVinyl: _isNeedleOnVinyl(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _vinylRotationController?.dispose();
    _needleController?.dispose();
    super.dispose();
  }
}

// Custom painter for the needle arm
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
