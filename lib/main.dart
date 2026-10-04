import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/player_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa orientasi portrait saja (pengalaman musik lebih baik)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set warna system UI agar sesuai dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // ProviderScope adalah root semua Riverpod providers
    const ProviderScope(child: MusicSyncApp()),
  );
}

/// Root widget aplikasi Music Sync.
/// Bertanggung jawab atas theme dan routing berbasis auth state.
class MusicSyncApp extends ConsumerWidget {
  const MusicSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Music Sync',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      // Routing sederhana: jika sudah login → Dashboard, jika belum → Login
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    // Saat masih memeriksa sesi tersimpan
    if (authState.isLoading && !authState.isLoggedIn) {
      return const _SplashScreen();
    }
    return authState.isLoggedIn ? const DashboardScreen() : const LoginScreen();
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1DB954),        // Spotify green
        secondary: Color(0xFF1DB954),
        surface: Color(0xFF282828),
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

/// Splash screen sementara saat mengecek sesi login
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Color(0xFF1DB954),
              size: 64,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF1DB954),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}