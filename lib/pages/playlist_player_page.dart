import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';
import '../widgets/audio_player_widget.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPlayerPage({super.key, required this.playlist});

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late PlaylistService _playlistService;
  int _currentSongIndex = 0;
  bool _isPlaying = false;
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playlistService = PlaylistService();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _playlistService.getPlaylistSongs(widget.playlist.id);
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading playlist songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playlistService.dispose();
    super.dispose();
  }

  void _playNextSong(List<Song> songs) {
    if (_currentSongIndex < songs.length - 1) {
      setState(() {
        _currentSongIndex++;
      });
      _playCurrentSong(songs);
    }
  }

  void _playPreviousSong(List<Song> songs) {
    if (_currentSongIndex > 0) {
      setState(() {
        _currentSongIndex--;
      });
      _playCurrentSong(songs);
    }
  }

  void _playCurrentSong(List<Song> songs) {
    if (_currentSongIndex < songs.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerWidget(
            song: songs[_currentSongIndex],
            playlist: songs,
            startIndex: _currentSongIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist: ${widget.playlist.name}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPlaylistContent(),
    );
  }

  Widget _buildPlaylistContent() {
    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No songs in this playlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add songs to this playlist to start playing',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Playlist Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _currentSongIndex > 0
                    ? () => _playPreviousSong(_songs)
                    : null,
                color: Colors.purple,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => _playCurrentSong(_songs),
                color: Colors.purple,
                iconSize: 32,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _currentSongIndex < _songs.length - 1
                    ? () => _playNextSong(_songs)
                    : null,
                color: Colors.purple,
              ),
            ],
          ),
        ),
        // Current Song Info
        if (_songs.isNotEmpty && _currentSongIndex < _songs.length)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        _songs[_currentSongIndex]
                            .thumbnailUrlGenerated
                            .isNotEmpty
                        ? Image.network(
                            _songs[_currentSongIndex].thumbnailUrlGenerated,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.music_note,
                                size: 30,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(
                            Icons.music_note,
                            size: 30,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _songs[_currentSongIndex].title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_currentSongIndex + 1} of ${_songs.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Songs List
        Expanded(
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              final song = _songs[index];
              final isCurrentSong = index == _currentSongIndex;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: isCurrentSong ? Colors.purple.withOpacity(0.1) : null,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: song.thumbnailUrlGenerated.isNotEmpty
                          ? Image.network(
                              song.thumbnailUrlGenerated,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.music_note,
                                  size: 20,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.music_note,
                              size: 20,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: isCurrentSong
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${index + 1} of ${_songs.length}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        _currentSongIndex = index;
                      });
                      _playCurrentSong(_songs);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _currentSongIndex = index;
                    });
                    _playCurrentSong(_songs);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
