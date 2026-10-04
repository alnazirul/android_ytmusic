import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/player_provider.dart';

/// Widget player musik yang persisten di bagian bawah layar.
/// Menampilkan judul lagu (dengan marquee jika panjang), tombol kontrol,
/// dan embed YouTube player (tanpa UI YouTube default).
class BottomPlayer extends ConsumerWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    if (playerState.controller == null || playerState.currentPlayingVideo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── YouTube Player tersembunyi (audio only experience) ──────
            SizedBox(
              height: 0, // Sembunyikan visual, hanya audio yang diperlukan
              child: YoutubePlayer(controller: playerState.controller!),
            ),

            // ── Progress Bar ───────────────────────────────────────────
            _ProgressBar(controller: playerState.controller!),

            // ── Info Lagu + Kontrol ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Judul lagu (marquee jika terlalu panjang)
                  Expanded(
                    child: _SongTitle(title: playerState.currentPlayingVideo!.title),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Previous
                  _ControlButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: () => ref.read(playerProvider.notifier).playPrevious(),
                  ),

                  // Tombol Play/Pause
                  _PlayPauseButton(
                    controller: playerState.controller!,
                    isPlaying: playerState.isPlaying,
                  ),

                  // Tombol Next
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    onTap: () => ref.read(playerProvider.notifier).playNext(),
                  ),

                  // Tombol Loop
                  _LoopButton(isLooping: playerState.isLooping),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SongTitle extends StatelessWidget {
  final String title;
  static const _marqueeThreshold = 30; // karakter

  const _SongTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    if (title.length <= _marqueeThreshold) {
      return Text(title, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    // Marquee (running text) untuk judul yang panjang
    return SizedBox(
      height: 20,
      child: Marquee(
        text: title,
        style: style,
        scrollAxis: Axis.horizontal,
        blankSpace: 60,
        velocity: 40,
        startAfter: const Duration(seconds: 2),
        pauseAfterRound: const Duration(seconds: 1),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final YoutubePlayerController controller;

  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: controller,
      builder: (context, value) {
        final position = value.position.inMilliseconds.toDouble();
        final duration = value.metaData.duration.inMilliseconds.toDouble();
        final progress = (duration > 0) ? (position / duration).clamp(0.0, 1.0) : 0.0;

        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          minHeight: 2,
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 28),
      onPressed: onTap,
      splashRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final YoutubePlayerController controller;
  final bool isPlaying;

  const _PlayPauseButton({required this.controller, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          controller.pauseVideo();
        } else {
          controller.playVideo();
        }
      },
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: Color(0xFF1DB954), // Spotify green
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.black,
          size: 26,
        ),
      ),
    );
  }
}

class _LoopButton extends ConsumerWidget {
  final bool isLooping;

  const _LoopButton({required this.isLooping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.repeat_rounded,
        color: isLooping ? const Color(0xFF1DB954) : Colors.white38,
        size: 22,
      ),
      onPressed: () => ref.read(playerProvider.notifier).toggleLoop(),
      splashRadius: 18,
      tooltip: isLooping ? 'Loop: ON' : 'Loop: OFF',
    );
  }
}
