library;


class YouTubePlaylist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final int? itemCount;

  YouTubePlaylist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.itemCount,
  });

  /// Parse dari response JSON YouTube API
  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final thumbUrl = (thumbnails['medium']?['url'] ??
            thumbnails['high']?['url'] ??
            thumbnails['default']?['url'] ??
            '') as String;

    final contentDetails =
        json['contentDetails'] as Map<String, dynamic>? ?? {};

    return YouTubePlaylist(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? 'Tanpa Judul',
      thumbnailUrl: thumbUrl,
      itemCount: contentDetails['itemCount'] != null
          ? int.tryParse(contentDetails['itemCount'].toString())
          : null,
    );
  }
}

class YouTubeVideo {
  final String id;
  final String title;
  final String? thumbnailUrl;

  YouTubeVideo({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });

  /// Parse dari response JSON YouTube playlistItems API
  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final resourceId = snippet['resourceId'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final thumbUrl = (thumbnails['medium']?['url'] ??
        thumbnails['default']?['url']) as String?;

    return YouTubeVideo(
      id: resourceId['videoId'] as String? ?? '',
      title: snippet['title'] as String? ?? 'Tanpa Judul',
      thumbnailUrl: thumbUrl,
    );
  }
}
