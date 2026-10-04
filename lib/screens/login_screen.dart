import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

/// Halaman login dengan desain dark Spotify-like.
/// Menampilkan tombol login Google dan animasi masuk yang halus.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Tampilkan error jika ada
    ref.listen(authProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo / Ikon ───────────────────────────────────────
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1DB954), Color(0xFF159640)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Judul ─────────────────────────────────────────────
                  const Text(
                    'Music Sync',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Subjudul ──────────────────────────────────────────
                  Text(
                    'Dengarkan playlist YouTube kamu\ndi mana saja, kapan saja.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Tombol Login Google ───────────────────────────────
                  _GoogleLoginButton(
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).login(),
                  ),

                  const SizedBox(height: 16),

                  // ── Disclaimer ────────────────────────────────────────
                  Text(
                    'Dengan masuk, kamu menyetujui akses\nread-only ke playlist YouTube kamu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleLoginButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 2.5,
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" ikon manual (tanpa asset)
                  _GoogleGIcon(),
                  const SizedBox(width: 12),
                  const Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Google "G" logo dibuat dengan CustomPaint
class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background putih bulat
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    // Warna-warna Google
    const colors = [
      Color(0xFF4285F4), // Biru
      Color(0xFF34A853), // Hijau
      Color(0xFFFBBC05), // Kuning
      Color(0xFFEA4335), // Merah
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    // Lingkaran sederhana empat bagian
    const sweeps = [0.5, 0.5, 0.5, 0.5];
    const starts = [0.1, 0.6, 1.1, 1.6];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        starts[i] * 3.14159,
        sweeps[i] * 3.14159,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
