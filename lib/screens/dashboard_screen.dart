import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/youtube_models.dart';
import '../providers/player_provider.dart';
import '../widgets/bottom_player.dart';
import 'playlist_screen.dart';

/// Halaman utama yang menampilkan semua playlist YouTube pengguna
/// dalam tampilan grid 2 kolom bergaya Spotify.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Otomatis muat playlist saat halaman pertama dibuka
    Future.microtask(() => ref.read(playerProvider.notifier).fetchMyPlaylists());
  }

  Future<void> _onRefresh() async {
    await ref.read(playerProvider.notifier).fetchMyPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                _DashboardAppBar(
                  userName: authState.userInfo?.name,
                  userPhotoUrl: authState.userInfo?.photoUrl,
                  onLogout: () {
                    ref.read(playerProvider.notifier).stopAndClear();
                    ref.read(authProvider.notifier).logout();
                  },
                ),

                // ── Judul Seksi ────────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'Playlist Kamu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // ── Loading State ──────────────────────────────────────
                if (playerState.isLoading && playerState.playlists.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                    ),
                  )

                // ── Error State ────────────────────────────────────────
                else if (playerState.errorMessage != null && playerState.playlists.isEmpty)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: playerState.errorMessage!,
                      onRetry: _onRefresh,
                    ),
                  )

                // ── Empty State ────────────────────────────────────────
                else if (playerState.playlists.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyView(onRefresh: _onRefresh),
                  )

                // ── Grid Playlist ──────────────────────────────────────
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _PlaylistCard(
                          playlist: playerState.playlists[index],
                          isActive: playerState.currentPlaylist?.id ==
                              playerState.playlists[index].id,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistScreen(
                                  playlist: playerState.playlists[index],
                                ),
                              ),
                            );
                          },
                        ),
                        childCount: playerState.playlists.length,
                      ),
                    ),
                  ),

                // Extra space di bawah untuk bottom player
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // ── Bottom Player ──────────────────────────────────────────────
          const BottomPlayer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final String? userName;
  final String? userPhotoUrl;
  final VoidCallback onLogout;

  const _DashboardAppBar({this.userName, this.userPhotoUrl, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      floating: true,
      snap: true,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          // Avatar pengguna
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1DB954),
            backgroundImage: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(userPhotoUrl!)
                : null,
            child: (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo,',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  userName ?? 'Pengguna',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          onPressed: onLogout,
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final YouTubePlaylist playlist;
  final bool isActive;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: const Color(0xFF1DB954), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: playlist.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: playlist.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _thumbnailPlaceholder(),
                        errorWidget: (_, __, ___) => _thumbnailPlaceholder(),
                      )
                    : _thumbnailPlaceholder(),
              ),
            ),

            // Info teks
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? const Color(0xFF1DB954) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (playlist.itemCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${playlist.itemCount} lagu',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: const Color(0xFF383838),
      child: const Center(
        child: Icon(Icons.queue_music_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.playlist_remove_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Belum ada playlist ditemukan.\nBuat playlist di YouTube terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1DB954),
                side: const BorderSide(color: Color(0xFF1DB954)),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
