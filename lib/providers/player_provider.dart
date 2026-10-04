import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/youtube_models.dart';
import '../services/auth_service.dart';
import '../services/youtube_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// State untuk autentikasi pengguna
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final GoogleUserInfo? userInfo;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.userInfo,
  });

  String? get token => userInfo?.token;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    GoogleUserInfo? userInfo,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userInfo: clearUser ? null : (userInfo ?? this.userInfo),
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

class AuthNotifier extends Notifier<AuthState> {
  final _authService = AuthService();

  @override
  AuthState build() {
    // Cek sesi yang tersimpan saat provider pertama kali dibuat
    Future.microtask(() => _checkSavedSession());
    return const AuthState(isLoading: true);
  }

  Future<void> _checkSavedSession() async {
    try {
      final userInfo = await _authService.getSavedSession();
      if (userInfo != null) {
        state = AuthState(isLoggedIn: true, userInfo: userInfo);
      } else {
        state = const AuthState(isLoggedIn: false);
      }
    } catch (_) {
      state = const AuthState(isLoggedIn: false);
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userInfo = await _authService.signIn();
      if (userInfo != null) {
        state = AuthState(isLoggedIn: true, userInfo: userInfo);
      } else {
        // Login dibatalkan pengguna
        state = const AuthState(isLoggedIn: false);
      }
    } catch (e) {
      state = AuthState(isLoggedIn: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = const AuthState(isLoggedIn: false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// State untuk pemutar musik dan daftar playlist/video
class AppPlayerState {
  final List<YouTubePlaylist> playlists;
  final YouTubePlaylist? currentPlaylist;
  final List<YouTubeVideo> currentPlaylistVideos;
  final YouTubeVideo? currentPlayingVideo;
  final bool isLoading;
  final String? errorMessage;
  final YoutubePlayerController? controller;
  final bool isLooping;
  final bool isPlaying;

  const AppPlayerState({
    this.playlists = const [],
    this.currentPlaylist,
    this.currentPlaylistVideos = const [],
    this.currentPlayingVideo,
    this.isLoading = false,
    this.errorMessage,
    this.controller,
    this.isLooping = false,
    this.isPlaying = false,
  });

  AppPlayerState copyWith({
    List<YouTubePlaylist>? playlists,
    YouTubePlaylist? currentPlaylist,
    List<YouTubeVideo>? currentPlaylistVideos,
    YouTubeVideo? currentPlayingVideo,
    bool? isLoading,
    String? errorMessage,
    YoutubePlayerController? controller,
    bool? isLooping,
    bool? isPlaying,
    bool clearError = false,
    bool clearCurrentVideo = false,
  }) {
    return AppPlayerState(
      playlists: playlists ?? this.playlists,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      currentPlaylistVideos: currentPlaylistVideos ?? this.currentPlaylistVideos,
      currentPlayingVideo:
          clearCurrentVideo ? null : (currentPlayingVideo ?? this.currentPlayingVideo),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      controller: controller ?? this.controller,
      isLooping: isLooping ?? this.isLooping,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

final playerProvider =
    NotifierProvider<PlayerNotifier, AppPlayerState>(() => PlayerNotifier());

class PlayerNotifier extends Notifier<AppPlayerState> {
  @override
  AppPlayerState build() {
    ref.onDispose(() => state.controller?.close());
    return const AppPlayerState();
  }

  /// Reset semua state player (saat logout)
  void stopAndClear() {
    state.controller?.close();
    state = const AppPlayerState();
  }

  /// Toggle mode loop untuk lagu yang sedang diputar
  void toggleLoop() {
    state = state.copyWith(isLooping: !state.isLooping, clearError: true);
  }

  /// Mengambil semua playlist dari YouTube API
  Future<void> fetchMyPlaylists() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = YouTubeService(token: token);
      final playlists = await service.fetchMyPlaylists();
      state = state.copyWith(playlists: playlists, isLoading: false);
    } on YouTubeAuthException {
      // Token sudah expired — paksa logout
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sesi habis. Silakan login ulang.',
      );
      await ref.read(authProvider.notifier).logout();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Membuka playlist dan langsung memutar video pertama
  Future<void> openPlaylist(YouTubePlaylist playlist) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(
      isLoading: true,
      currentPlaylist: playlist,
      currentPlaylistVideos: [],
      clearError: true,
    );

    try {
      final service = YouTubeService(token: token);
      final videos = await service.fetchPlaylistItems(playlist.id);

      if (videos.isEmpty) {
        throw Exception('Playlist kosong atau semua video bersifat privat.');
      }

      // Inisialisasi atau gunakan kembali controller yang sudah ada
      final controller = _getOrCreateController();

      // Muat video pertama dengan kualitas 144p (hemat data)
      controller.loadVideoById(videoId: videos.first.id);

      state = state.copyWith(
        currentPlaylistVideos: videos,
        currentPlayingVideo: videos.first,
        controller: controller,
        isLoading: false,
        isPlaying: true,
      );
    } on YouTubeAuthException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sesi habis. Silakan login ulang.',
      );
      await ref.read(authProvider.notifier).logout();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Memutar video tertentu dari daftar playlist yang sudah dimuat
  void playVideo(YouTubeVideo video) {
    if (state.controller == null) return;
    state.controller!.loadVideoById(videoId: video.id);
    state = state.copyWith(currentPlayingVideo: video, isPlaying: true, clearError: true);
  }

  /// Maju ke video berikutnya
  void playNext() {
    final videos = state.currentPlaylistVideos;
    final current = state.currentPlayingVideo;
    if (current == null || videos.isEmpty) return;

    final currentIndex = videos.indexWhere((v) => v.id == current.id);

    if (state.isLooping) {
      // Mode loop: putar ulang lagu yang sama
      state.controller?.loadVideoById(videoId: current.id);
      return;
    }

    if (currentIndex != -1 && currentIndex < videos.length - 1) {
      final nextVideo = videos[currentIndex + 1];
      state.controller?.loadVideoById(videoId: nextVideo.id);
      state = state.copyWith(currentPlayingVideo: nextVideo, clearError: true);
    }
    // Jika sudah di akhir playlist, berhenti (tidak berulang otomatis)
  }

  /// Kembali ke video sebelumnya
  void playPrevious() {
    final videos = state.currentPlaylistVideos;
    final current = state.currentPlayingVideo;
    if (current == null || videos.isEmpty) return;

    final currentIndex = videos.indexWhere((v) => v.id == current.id);
    if (currentIndex > 0) {
      final prevVideo = videos[currentIndex - 1];
      state.controller?.loadVideoById(videoId: prevVideo.id);
      state = state.copyWith(currentPlayingVideo: prevVideo, clearError: true);
    }
  }

  /// Membuat atau menggunakan kembali YoutubePlayerController
  YoutubePlayerController _getOrCreateController() {
    if (state.controller != null) return state.controller!;

    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: false,
        showControls: false, // Kita buat kontrol sendiri
        showFullscreenButton: false,
      ),
    );

    // Tanam listener event di sini (bukan di UI)
    controller.listen((event) {
      if (event.playerState == PlayerState.ended) {
        playNext();
      }
      if (event.playerState == PlayerState.playing) {
        state = state.copyWith(isPlaying: true);
      }
      if (event.playerState == PlayerState.paused) {
        state = state.copyWith(isPlaying: false);
      }
    });

    return controller;
  }
}
