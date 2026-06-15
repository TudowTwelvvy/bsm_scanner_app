import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// WHY: JWT tokens are like house keys. If someone steals them, they can
// impersonate the user. Storing in SharedPreferences is like leaving your
// key under the doormat — any app with root access can read it.
//
// FlutterSecureStorage encrypts data using:
// - iOS: Keychain (hardware-backed encryption)
// - Android: Keystore system (hardware-backed on modern devices)
class SecureStorageService {
  // aOptions = Android-specific options.
  // encryptedSharedPreferences: true forces encryption even on older Android
  // devices that don't have hardware Keystore.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Using a constant prevents typos. If you write 'jwt_tooken' in one place
  // and 'jwt_token' in another, you'd have a bug that's hard to find.
  static const _tokenKey = 'jwt_token';

  // async/await because secure storage involves native platform channels
  // (Dart -> Platform Channel -> OS Keychain -> Platform Channel -> Dart).
  // This takes milliseconds but is not instantaneous.
  Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}