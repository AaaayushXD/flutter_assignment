import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/song_service.dart';
import '../services/playlist_service.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../widgets/add_song_dialog.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/create_playlist_dialog.dart';
import '../widgets/global_theme_switcher.dart';
import 'playlist_player_page.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late SongService _songService;
  late PlaylistService _playlistService;
  Playlist? _selectedPlaylist;

  // Data storage
  List<Song> _songs = [];
  List<Playlist> _playlists = [];
  bool _isLoadingSongs = false;
  bool _isLoadingPlaylists = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _songService = SongService();
    _playlistService = PlaylistService();

    // Add tab listener for debugging
    _tabController.addListener(() {
      print('Tab changed to index: ${_tabController.index}');
    });

    // Load data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        _loadData();
        print('SongsPage initialized with user: ${authProvider.user?.uid}');
      }
    });
  }

  Future<void> _loadData() async {
    await _loadSongs();
    await _loadPlaylists();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoadingSongs = true;
    });

    try {
      final songs = await _songService.getUserSongs();
      setState(() {
        _songs = songs;
        _isLoadingSongs = false;
      });
    } catch (e) {
      print('Error loading songs: $e');
      setState(() {
        _isLoadingSongs = false;
      });
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      final playlists = await _playlistService.getUserPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      print('Error loading playlists: $e');
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _songService.dispose();
    _playlistService.dispose();
    super.dispose();
  }

  void _showAddSongDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddSongDialog(selectedPlaylistId: _selectedPlaylist?.id),
    ).then((_) {
      // Refresh data after dialog closes
      _loadData();
    });
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    ).then((_) {
      // Refresh playlists after dialog closes
      _loadPlaylists();
    });
  }

  void _editSong(Song song) {
    showDialog(
      context: context,
      builder: (context) => AddSongDialog(
        initialTitle: song.title,
        initialYoutubeUrl: song.youtubeUrl,
      ),
    );
  }

  void _deleteSong(Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _songService.deleteSong(song.id);
                Navigator.pop(context);
                _loadData(); // Refresh data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Song deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting song: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _playlistService.deletePlaylist(playlist.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting playlist: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _playSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AudioPlayerWidget(song: song)),
    );
  }

  void _playPlaylist(Playlist playlist) async {
    // Navigate to the vinyl playlist player
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistPlayerPage(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('SongsPage build called - User: ${authProvider.user?.uid}');

        // Refresh data when auth state changes
        if (authProvider.user != null) {
          // The StreamBuilder widgets will handle the data loading
        }

        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDarkMode = themeProvider.isDarkMode;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Welcome, ${authProvider.user?.displayName ?? authProvider.user?.email?.split('@')[0] ?? 'User'}!',
                ),
                backgroundColor: isDarkMode
                    ? const Color(0xFF16213E)
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
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              body: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildSongsTab(), _buildPlaylistsTab()],
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: _showAddSongDialog,
                backgroundColor: isDarkMode
                    ? const Color(0xFF16213E)
                    : Colors.purple,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.purple,
        tabs: const [
          Tab(text: 'Songs', icon: Icon(Icons.music_note)),
          Tab(text: 'Playlists', icon: Icon(Icons.playlist_play)),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_isLoadingSongs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _buildSongCard(song);
      },
    );
  }

  Widget _buildPlaylistsTab() {
    if (_isLoadingPlaylists) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading playlists...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Create Playlist Button and Refresh
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreatePlaylistDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Playlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _loadPlaylists();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Playlists',
              ),
            ],
          ),
        ),
        // Playlists List
        Expanded(
          child: _playlists.isEmpty
              ? _buildEmptyPlaylistState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return _buildPlaylistCard(playlist);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSongCard(Song song) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _playSong(song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: song.thumbnailUrlGenerated.isNotEmpty
                      ? Image.network(
                          song.thumbnailUrlGenerated,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                                size: 30,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added by ${song.userName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added ${_formatDate(song.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Actions - Only the triple dot menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editSong(song);
                      break;
                    case 'delete':
                      _deleteSong(song);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _playPlaylist(playlist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Playlist Image/Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
                      ? Image.network(
                          playlist.imageUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.playlist_play,
                                color: Colors.purple,
                                size: 30,
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.playlist_play,
                          color: Colors.purple,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Playlist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.songCount} songs',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${_formatDate(playlist.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _deletePlaylist(playlist);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No songs yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first song by tapping the + button',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaylistState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_play, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No playlists yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first playlist to organize your songs',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
