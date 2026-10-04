import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk menangani autentikasi Google dan manajemen token OAuth.
/// Tidak bergantung pada Riverpod — murni logika auth.
class AuthService {
  static const _tokenKey = 'yt_access_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userPhotoKey = 'user_photo';

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/youtube.readonly',
      'email',
      'profile',
    ],
  );

  final _secureStorage = const FlutterSecureStorage();

  /// Memulai proses login Google. Mengembalikan access token jika sukses,
  /// null jika pengguna membatalkan login, atau melempar Exception jika error.
  Future<GoogleUserInfo?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // Login dibatalkan pengguna

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) throw Exception('Gagal mendapatkan access token dari Google.');

    // Simpan token dan info pengguna secara aman
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userNameKey, value: account.displayName ?? '');
    await _secureStorage.write(key: _userEmailKey, value: account.email);
    await _secureStorage.write(key: _userPhotoKey, value: account.photoUrl ?? '');

    return GoogleUserInfo(
      token: token,
      name: account.displayName ?? '',
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }

  /// Logout dari Google dan hapus semua data tersimpan.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _secureStorage.deleteAll();
  }

  /// Memeriksa apakah sudah ada sesi login yang tersimpan.
  /// Mengembalikan [GoogleUserInfo] jika ada, atau null jika belum login.
  Future<GoogleUserInfo?> getSavedSession() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return null;

    final name = await _secureStorage.read(key: _userNameKey) ?? '';
    final email = await _secureStorage.read(key: _userEmailKey) ?? '';
    final photoUrl = await _secureStorage.read(key: _userPhotoKey);

    return GoogleUserInfo(
      token: token,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }
}

/// Data class untuk menyimpan informasi pengguna yang sudah login.
class GoogleUserInfo {
  final String token;
  final String name;
  final String email;
  final String? photoUrl;

  const GoogleUserInfo({
    required this.token,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}
