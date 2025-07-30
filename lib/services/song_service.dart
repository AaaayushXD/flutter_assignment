import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_model.dart';

class SongService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for broadcasting
  final StreamController<List<Song>> _userSongsController =
      StreamController<List<Song>>.broadcast();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Add a new song
  Future<void> addSong({
    required String title,
    required String youtubeUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('Adding song for user: ${user.uid}');
      print('Song title: $title');

      final song = Song(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        youtubeUrl: youtubeUrl,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      print('Saving song to Firestore...');
      await _firestore.collection('songs').doc(song.id).set(song.toJson());
      print('Song saved successfully to Firestore');

      // Refresh streams
      _refreshUserSongs();
    } catch (e) {
      print('Error adding song: $e');
      rethrow;
    }
  }

  // Get all songs for current user
  Future<List<Song>> getUserSongs() async {
    return await _getUserSongs();
  }

  Future<List<Song>> _getUserSongs() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('No user authenticated, returning empty songs list');
        return [];
      }

      print('Getting songs for user: ${user.uid}');

      // Get songs from Firestore with timeout
      final querySnapshot = await _firestore
          .collection('songs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final songs = querySnapshot.docs
          .map((doc) => Song.fromJson(doc.data()))
          .toList();

      print('Found ${songs.length} songs for user');

      return songs;
    } catch (e) {
      print('Error getting user songs: $e');
      return [];
    }
  }

  Future<void> _refreshUserSongs() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('No user authenticated, returning empty songs list');
        _userSongsController.add([]);
        return;
      }

      print('Refreshing songs for user: ${user.uid}');

      // Get songs from Firestore with timeout
      final querySnapshot = await _firestore
          .collection('songs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final songs = querySnapshot.docs
          .map((doc) => Song.fromJson(doc.data()))
          .toList();

      print('Found ${songs.length} songs for user');

      // Add a small delay to ensure stream is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Only add if the controller is not closed
      if (!_userSongsController.isClosed) {
        _userSongsController.add(songs);
      }
    } catch (e) {
      print('Error refreshing user songs: $e');
      if (!_userSongsController.isClosed) {
        _userSongsController.add([]);
      }
    }
  }

  // Update a song
  Future<void> updateSong({
    required String songId,
    required String title,
    required String youtubeUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update in Firestore
      await _firestore.collection('songs').doc(songId).update({
        'title': title,
        'youtubeUrl': youtubeUrl,
      });

      // Refresh streams
      _refreshUserSongs();
    } catch (e) {
      print('Error updating song: $e');
      rethrow;
    }
  }

  // Delete a song
  Future<void> deleteSong(String songId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('songs').doc(songId).delete();

      // Refresh streams
      _refreshUserSongs();
    } catch (e) {
      print('Error deleting song: $e');
      rethrow;
    }
  }

  // Dispose method to clean up stream controllers
  void dispose() {
    _userSongsController.close();
  }
}
