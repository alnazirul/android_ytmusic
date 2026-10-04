import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/youtube_models.dart';
import '../providers/player_provider.dart';
import '../widgets/bottom_player.dart';
import '../widgets/playlist_tile.dart';

/// Halaman yang menampilkan daftar lagu dalam sebuah playlist.
/// Termasuk header playlist, ListView lagu, dan bottom player persisten.
class PlaylistScreen extends ConsumerStatefulWidget {
  final YouTubePlaylist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    // Muat dan mainkan playlist ini
    Future.microtask(
      () => ref.read(playerProvider.notifier).openPlaylist(widget.playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Sliver App Bar dengan Thumbnail ────────────────────
                _PlaylistSliverAppBar(playlist: widget.playlist),

                // ── Header Info ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _PlaylistHeader(playlist: widget.playlist),
                ),

                // ── Loading State ──────────────────────────────────────
                if (playerState.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                    ),
                  )

                // ── Error State ────────────────────────────────────────
                else if (playerState.errorMessage != null &&
                    playerState.currentPlaylistVideos.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          playerState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ),
                  )

                // ── Daftar Lagu ────────────────────────────────────────
                else if (playerState.currentPlaylistVideos.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final video = playerState.currentPlaylistVideos[index];
                          final isPlaying =
                              playerState.currentPlayingVideo?.id == video.id;
                          return PlaylistTile(
                            video: video,
                            isPlaying: isPlaying,
                            onTap: () =>
                                ref.read(playerProvider.notifier).playVideo(video),
                          );
                        },
                        childCount: playerState.currentPlaylistVideos.length,
                      ),
                    ),
                  ),

                // Padding bawah untuk bottom player
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // ── Bottom Player Persisten ────────────────────────────────────
          const BottomPlayer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistSliverAppBar extends StatelessWidget {
  final YouTubePlaylist playlist;

  const _PlaylistSliverAppBar({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      expandedHeight: 220,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail sebagai background
            if (playlist.thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: playlist.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Color(0xFF282828)),
                errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF282828)),
              )
            else
              const ColoredBox(color: Color(0xFF282828)),

            // Gradient overlay untuk keterbacaan teks
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                    Color(0xFF121212),
                  ],
                  stops: [0.4, 0.75, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  final YouTubePlaylist playlist;

  const _PlaylistHeader({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          if (playlist.itemCount != null) ...[
            const SizedBox(height: 6),
            Text(
              '${playlist.itemCount} lagu',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
        ],
      ),
    );
  }
}
