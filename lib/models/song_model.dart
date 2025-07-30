class Song {
  final String id;
  final String title;
  final String youtubeUrl;
  final String userId;
  final String userName;
  final DateTime createdAt;

  Song({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'youtubeUrl': youtubeUrl,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      youtubeUrl: json['youtubeUrl'],
      userId: json['userId'],
      userName: json['userName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Copy with method for updates
  Song copyWith({
    String? id,
    String? title,
    String? youtubeUrl,
    String? userId,
    String? userName,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get YouTube video ID from URL
  String? get videoId {
    final uri = Uri.tryParse(youtubeUrl);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  // Generate thumbnail URL
  String get thumbnailUrlGenerated {
    final videoId = this.videoId;
    if (videoId == null) return '';
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }
}
