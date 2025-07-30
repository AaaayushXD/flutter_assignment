class Playlist {
  final String id;
  final String name;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> songIds; // References to song IDs
  final String? imageUrl; // Optional playlist image URL

  Playlist({
    required this.id,
    required this.name,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    required this.songIds,
    this.imageUrl,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'songIds': songIds,
      'imageUrl': imageUrl,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      userId: json['userId'],
      userName: json['userName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      songIds: List<String>.from(json['songIds'] ?? []),
      imageUrl: json['imageUrl'],
    );
  }

  // Copy with method for updates
  Playlist copyWith({
    String? id,
    String? name,
    String? userId,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? songIds,
    String? imageUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songIds: songIds ?? this.songIds,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Add a song to the playlist
  Playlist addSong(String songId) {
    if (!songIds.contains(songId)) {
      final newSongIds = List<String>.from(songIds)..add(songId);
      return copyWith(songIds: newSongIds, updatedAt: DateTime.now());
    }
    return this;
  }

  // Remove a song from the playlist
  Playlist removeSong(String songId) {
    if (songIds.contains(songId)) {
      final newSongIds = List<String>.from(songIds)..remove(songId);
      return copyWith(songIds: newSongIds, updatedAt: DateTime.now());
    }
    return this;
  }

  // Get song count
  int get songCount => songIds.length;

  // Check if playlist is empty
  bool get isEmpty => songIds.isEmpty;
}
