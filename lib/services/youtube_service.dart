import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_models.dart';

/// Service untuk berkomunikasi dengan YouTube Data API v3.
/// Semua HTTP request ke Google API dikumpulkan di sini.
class YouTubeService {
  final String token;

  static const _baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  /// Mengambil semua playlist milik pengguna yang sedang login.
  /// Mendukung pagination otomatis (mengambil semua halaman).
  Future<List<YouTubePlaylist>> fetchMyPlaylists() async {
    final List<YouTubePlaylist> allPlaylists = [];
    String? nextPageToken;

    do {
      final queryParams = {
        'part': 'snippet,contentDetails',
        'mine': 'true',
        'maxResults': '50',
        if (nextPageToken != null) 'pageToken': nextPageToken,
      };

      final url = Uri.parse('$_baseUrl/playlists').replace(queryParameters: queryParams);
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 401) {
        throw YouTubeAuthException('Token tidak valid atau sudah kedaluwarsa. Silakan login ulang.');
      }

      if (response.statusCode != 200) {
        throw YouTubeApiException(
          'Gagal mengambil playlist. Status: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      for (final item in items) {
        allPlaylists.add(YouTubePlaylist.fromJson(item as Map<String, dynamic>));
      }

      nextPageToken = data['nextPageToken'] as String?;
    } while (nextPageToken != null);

    return allPlaylists;
  }

  /// Mengambil semua item (video) dari sebuah playlist berdasarkan [playlistId].
  /// Secara otomatis menangani pagination dan memfilter video privat/terhapus.
  Future<List<YouTubeVideo>> fetchPlaylistItems(String playlistId) async {
    final List<YouTubeVideo> allVideos = [];
    String? nextPageToken;

    do {
      final queryParams = {
        'part': 'snippet',
        'playlistId': playlistId,
        'maxResults': '50',
        if (nextPageToken != null) 'pageToken': nextPageToken,
      };

      final url = Uri.parse('$_baseUrl/playlistItems').replace(queryParameters: queryParams);
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 401) {
        throw YouTubeAuthException('Token tidak valid atau sudah kedaluwarsa. Silakan login ulang.');
      }

      if (response.statusCode != 200) {
        throw YouTubeApiException(
          'Gagal mengambil isi playlist. Status: ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      for (final item in items) {
        final video = YouTubeVideo.fromJson(item as Map<String, dynamic>);

        // Filter: skip video privat, terhapus, atau ID kosong
        if (video.id.isNotEmpty &&
            video.title != 'Private video' &&
            video.title != 'Deleted video') {
          allVideos.add(video);
        }
      }

      nextPageToken = data['nextPageToken'] as String?;
    } while (nextPageToken != null);

    return allVideos;
  }
}

// ── Custom Exceptions ─────────────────────────────────────────────────────────

/// Dilempar ketika token sudah tidak valid (HTTP 401).
class YouTubeAuthException implements Exception {
  final String message;
  YouTubeAuthException(this.message);
  @override
  String toString() => message;
}

/// Dilempar untuk error API umum selain auth.
class YouTubeApiException implements Exception {
  final String message;
  final int statusCode;
  YouTubeApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
