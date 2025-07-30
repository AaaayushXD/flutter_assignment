import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../services/song_service.dart';
import '../services/playlist_service.dart';
import '../services/youtube_audio_service.dart';

class AddSongDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialYoutubeUrl;
  final String? selectedPlaylistId;

  const AddSongDialog({
    super.key,
    this.initialTitle,
    this.initialYoutubeUrl,
    this.selectedPlaylistId,
  });

  @override
  State<AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends State<AddSongDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _newPlaylistController = TextEditingController();
  final _songService = SongService();
  final _playlistService = PlaylistService();
  final _youtubeService = YouTubeAudioService();
  bool _isLoading = false;
  bool _isCreatingNewPlaylist = false;
  bool _isValidatingUrl = false;
  String? _selectedPlaylistId;
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _youtubeUrlController.text = widget.initialYoutubeUrl ?? '';
    _selectedPlaylistId = widget.selectedPlaylistId;
    _loadPlaylists();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _youtubeUrlController.dispose();
    _newPlaylistController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlistsStream = _playlistService.getUserPlaylists().asStream();
      await for (final playlists in playlistsStream) {
        if (mounted) {
          setState(() {
            _playlists = playlists;
          });
        }
      }
    } catch (e) {
      print('Error loading playlists: $e');
    }
  }

  Future<void> _validateAndFillYouTubeUrl() async {
    final url = _youtubeUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isValidatingUrl = true;
    });

    try {
      // Validate YouTube URL
      final isValid = await _youtubeService.isValidYouTubeVideo(url);

      if (isValid) {
        // Get video details and auto-fill title if empty
        final videoDetails = await _youtubeService.getVideoDetails(url);
        if (videoDetails != null && _titleController.text.trim().isEmpty) {
          setState(() {
            _titleController.text = videoDetails['title'] ?? '';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Valid YouTube URL! Auto-filled title: ${videoDetails['title']}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Invalid YouTube URL. Please check the URL and try again.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error validating YouTube URL: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingUrl = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTitle != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Song' : 'Add New Song'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a song title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _youtubeUrlController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://www.youtube.com/watch?v=...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a YouTube URL';
                      }
                      if (!value.contains('youtube.com') &&
                          !value.contains('youtu.be')) {
                        return 'Please enter a valid YouTube URL';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isValidatingUrl
                      ? null
                      : _validateAndFillYouTubeUrl,
                  icon: _isValidatingUrl
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  tooltip: 'Validate YouTube URL and auto-fill title',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Playlist Selection
            if (!_isCreatingNewPlaylist) ...[
              DropdownButtonFormField<String>(
                value: _selectedPlaylistId,
                decoration: const InputDecoration(
                  labelText: 'Select Playlist',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No Playlist'),
                  ),
                  ..._playlists.map(
                    (playlist) => DropdownMenuItem<String>(
                      value: playlist.id,
                      child: Text(playlist.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPlaylistId = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isCreatingNewPlaylist = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Playlist'),
              ),
            ] else ...[
              TextFormField(
                controller: _newPlaylistController,
                decoration: const InputDecoration(
                  labelText: 'New Playlist Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a playlist name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isCreatingNewPlaylist = false;
                    _newPlaylistController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Select Existing Playlist'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSong,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveSong() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Add the song first
        await _songService.addSong(
          title: _titleController.text.trim(),
          youtubeUrl: _youtubeUrlController.text.trim(),
        );

        // If creating a new playlist, create it first
        String? playlistId = _selectedPlaylistId;
        if (_isCreatingNewPlaylist) {
          await _playlistService.createPlaylist(
            _newPlaylistController.text.trim(),
          );
          // Get the newly created playlist
          final playlistsStream = _playlistService
              .getUserPlaylists()
              .asStream();
          await for (final playlists in playlistsStream.take(1)) {
            final newPlaylist = playlists.firstWhere(
              (p) => p.name == _newPlaylistController.text.trim(),
              orElse: () => throw Exception('New playlist not found'),
            );
            playlistId = newPlaylist.id;
            break;
          }
        }

        // If a playlist is selected, add the song to it
        if (playlistId != null) {
          // Get the song ID from the stream
          final songsStream = _songService.getUserSongs().asStream();
          await for (final songs in songsStream.take(1)) {
            final newSong = songs.firstWhere(
              (s) =>
                  s.title == _titleController.text.trim() &&
                  s.youtubeUrl == _youtubeUrlController.text.trim(),
              orElse: () => throw Exception('New song not found'),
            );
            await _playlistService.addSongToPlaylist(playlistId, newSong.id);
            break;
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialTitle != null
                    ? 'Song updated successfully'
                    : 'Song added successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
