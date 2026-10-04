import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/youtube_models.dart';

/// Widget tile untuk satu item lagu dalam sebuah playlist.
/// Menampilkan thumbnail, judul, dan indikator "sedang diputar".
class PlaylistTile extends StatelessWidget {
  final YouTubeVideo video;
  final bool isPlaying;
  final VoidCallback onTap;

  const PlaylistTile({
    super.key,
    required this.video,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isPlaying
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ── Thumbnail ───────────────────────────────────────────────
              _buildThumbnail(),
              const SizedBox(width: 12),

              // ── Judul Lagu ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying
                            ? const Color(0xFF1DB954) // Spotify green
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Indikator Playing ────────────────────────────────────────
              if (isPlaying)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: _EqualizerIcon(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const size = 52.0;
    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: video.thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _placeholderBox(size),
          errorWidget: (context, url, error) => _placeholderBox(size),
        ),
      );
    }
    return _placeholderBox(size);
  }

  Widget _placeholderBox(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
    );
  }
}

/// Animasi ikon equalizer saat lagu sedang diputar
class _EqualizerIcon extends StatefulWidget {
  const _EqualizerIcon();

  @override
  State<_EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<_EqualizerIcon>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 4, end: 18).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Container(
              width: 4,
              height: _animations[i].value,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
