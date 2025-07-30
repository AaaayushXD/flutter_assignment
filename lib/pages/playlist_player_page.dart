import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';
import '../widgets/playlist_vinyl_player.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPlayerPage({super.key, required this.playlist});

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late PlaylistService _playlistService;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Playlist: ${widget.playlist.name}'),
          backgroundColor: const Color(0xFF16213E),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_songs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Playlist: ${widget.playlist.name}'),
          backgroundColor: const Color(0xFF16213E),
          foregroundColor: Colors.white,
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
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
                  color: Colors.grey[300],
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
        ),
      );
    }

    return PlaylistVinylPlayer(playlist: widget.playlist, songs: _songs);
  }
}
