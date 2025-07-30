import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class PlaylistService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for broadcasting
  final StreamController<List<Playlist>> _userPlaylistsController =
      StreamController<List<Playlist>>.broadcast();
  final StreamController<List<Song>> _playlistSongsController =
      StreamController<List<Song>>.broadcast();

  PlaylistService() {
    // Initialize with empty lists
    if (!_userPlaylistsController.isClosed) {
      _userPlaylistsController.add([]);
    }
    if (!_playlistSongsController.isClosed) {
      _playlistSongsController.add([]);
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Create a new playlist
  Future<void> createPlaylist(String name) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('Creating playlist: $name for user: ${user.uid}');

      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        songIds: [],
      );

      // Save to Firestore
      await _firestore
          .collection('playlists')
          .doc(playlist.id)
          .set(playlist.toJson());
      print('Playlist created successfully');

      // Refresh playlists
      _refreshUserPlaylists();
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  // Get all playlists for current user
  Future<List<Playlist>> getUserPlaylists() async {
    return await _getUserPlaylists();
  }

  Future<List<Playlist>> _getUserPlaylists() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('No user authenticated, returning empty playlists list');
        return [];
      }

      print('Getting playlists for user: ${user.uid}');

      // Get playlists from Firestore with timeout
      final querySnapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final playlists = querySnapshot.docs
          .map((doc) => Playlist.fromJson(doc.data()))
          .toList();

      print(
        'Found ${playlists.length} playlists: ${playlists.map((p) => p.name).join(', ')}',
      );

      return playlists;
    } catch (e) {
      print('Error getting user playlists: $e');
      return [];
    }
  }

  Future<void> _refreshUserPlaylists() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('No user authenticated, returning empty playlists list');
        if (!_userPlaylistsController.isClosed) {
          _userPlaylistsController.add([]);
        }
        return;
      }

      print('Refreshing playlists for user: ${user.uid}');

      // Get playlists from Firestore with timeout
      final querySnapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final playlists = querySnapshot.docs
          .map((doc) => Playlist.fromJson(doc.data()))
          .toList();

      print(
        'Found ${playlists.length} playlists: ${playlists.map((p) => p.name).join(', ')}',
      );

      // Add a small delay to ensure stream is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Only add if the controller is not closed
      if (!_userPlaylistsController.isClosed) {
        print('Adding ${playlists.length} playlists to stream');
        _userPlaylistsController.add(playlists);
      } else {
        print('Stream controller is closed, cannot add playlists');
      }
    } catch (e) {
      print('Error refreshing user playlists: $e');
      if (!_userPlaylistsController.isClosed) {
        _userPlaylistsController.add([]);
      }
    }
  }

  // Get songs in a specific playlist
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    return await _getPlaylistSongs(playlistId);
  }

  Future<List<Song>> _getPlaylistSongs(String playlistId) async {
    try {
      // Get the playlist first
      final playlistDoc = await _firestore
          .collection('playlists')
          .doc(playlistId)
          .get();
      if (!playlistDoc.exists) {
        return [];
      }

      final playlist = Playlist.fromJson(playlistDoc.data()!);

      if (playlist.songIds.isEmpty) {
        return [];
      }

      // Get all songs in the playlist
      final songs = <Song>[];
      for (final songId in playlist.songIds) {
        final songDoc = await _firestore.collection('songs').doc(songId).get();
        if (songDoc.exists) {
          songs.add(Song.fromJson(songDoc.data()!));
        }
      }

      // Sort by creation date
      songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return songs;
    } catch (e) {
      print('Error getting playlist songs: $e');
      return [];
    }
  }

  Future<void> _refreshPlaylistSongs(String playlistId) async {
    try {
      // Get the playlist first
      final playlistDoc = await _firestore
          .collection('playlists')
          .doc(playlistId)
          .get();
      if (!playlistDoc.exists) {
        _playlistSongsController.add([]);
        return;
      }

      final playlist = Playlist.fromJson(playlistDoc.data()!);

      if (playlist.songIds.isEmpty) {
        _playlistSongsController.add([]);
        return;
      }

      // Get all songs in the playlist
      final songs = <Song>[];
      for (final songId in playlist.songIds) {
        final songDoc = await _firestore.collection('songs').doc(songId).get();
        if (songDoc.exists) {
          songs.add(Song.fromJson(songDoc.data()!));
        }
      }

      // Sort by creation date
      songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!_playlistSongsController.isClosed) {
        _playlistSongsController.add(songs);
      }
    } catch (e) {
      print('Error refreshing playlist songs: $e');
      if (!_playlistSongsController.isClosed) {
        _playlistSongsController.add([]);
      }
    }
  }

  // Add a song to a playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final playlistDoc = await _firestore
          .collection('playlists')
          .doc(playlistId)
          .get();
      if (!playlistDoc.exists) throw Exception('Playlist not found');

      final playlist = Playlist.fromJson(playlistDoc.data()!);
      final updatedPlaylist = playlist.addSong(songId);

      await _firestore
          .collection('playlists')
          .doc(playlistId)
          .update(updatedPlaylist.toJson());

      // Refresh playlists and songs
      _refreshUserPlaylists();
      _refreshPlaylistSongs(playlistId);
    } catch (e) {
      print('Error adding song to playlist: $e');
      rethrow;
    }
  }

  // Remove a song from a playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final playlistDoc = await _firestore
          .collection('playlists')
          .doc(playlistId)
          .get();
      if (!playlistDoc.exists) throw Exception('Playlist not found');

      final playlist = Playlist.fromJson(playlistDoc.data()!);
      final updatedPlaylist = playlist.removeSong(songId);

      await _firestore
          .collection('playlists')
          .doc(playlistId)
          .update(updatedPlaylist.toJson());

      // Refresh playlists and songs
      _refreshUserPlaylists();
      _refreshPlaylistSongs(playlistId);
    } catch (e) {
      print('Error removing song from playlist: $e');
      rethrow;
    }
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
      _refreshUserPlaylists();
    } catch (e) {
      print('Error deleting playlist: $e');
      rethrow;
    }
  }

  // Update playlist name
  Future<void> updatePlaylistName(String playlistId, String newName) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'name': newName,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _refreshUserPlaylists();
    } catch (e) {
      print('Error updating playlist name: $e');
      rethrow;
    }
  }

  // Dispose method to clean up stream controllers
  void dispose() {
    _userPlaylistsController.close();
    _playlistSongsController.close();
  }
}
