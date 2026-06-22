import 'dart:async';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/network/auth_events.dart';
import '../../../core/services/secure_storage_service.dart';
import '../domain/user.dart';

class AuthException implements Exception {
  final String code;      //Machine-readable code (e.g., 'email-already-in-use')
  final String message;   //Human-readable message

  AuthException(this.code, this.message);
}

class AuthRepository {
  final Dio _dio;         //HTTP client for API calls
  final SecureStorageService _storage; //Encrypted token storage

  final _authController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _authController.stream;

  AuthRepository(this._dio, this._storage) {
    _init();
    // Listen for global 401 events from Dio. When the API says "token expired",
    // we log out automatically. This prevents the user from seeing infinite
    // loading spinners on every screen.
    AuthEvents.onUnauthorized.listen((_) => signOut());
  }

  //when app starts Check for existing token
  Future<void> _init() async {
    final token = await _storage.readToken();

    // JwtDecoder.isExpired checks the 'exp' claim in the JWT payload.
    // No network request needed... it's pure math on the local token.
    if (token != null && !JwtDecoder.isExpired(token)) {
      _authController.add(_decodeUser(token));
    } else {
      // Token missing or expired. Delete it to prevent sending stale tokens.
      await _storage.deleteToken();
      _authController.add(null); // null = no user logged in
    }
  }

  //DECODE JWT 
  //The JWT contains claims (sub, email, name, role)... We extract these into our domain User object so the rest of the app doesn't touch JWTs.
  User _decodeUser(String token) {
    final decoded = JwtDecoder.decode(token);

    // 'sub' = subject = the user's ID. Identity puts the Guid string here.
    final id = decoded['sub'] as String;

    // 'role' can be a single string or a list of strings (if user has multiple roles).
    // We normalize to a List<String> so the UI always gets the same type.
    final roles = _parseRoles(decoded['role']);

    return User(
      id: id,
      email: decoded['email'] as String,
      displayName: decoded['name'] as String?,
      roles: roles,
      createdAt: DateTime.now(), // JWT doesn't store this, default to now
    );
  }

  List<String> _parseRoles(dynamic roleClaim) {
    if (roleClaim == null) return ['User']; // Default role
    if (roleClaim is List) return roleClaim.cast<String>();
    return [roleClaim.toString()];
  }

  //LOGIN 
  Future<void> signInWithEmail({
    required String email,
    required String password,
    }) async {
      //print('🔐 LOGIN START: $email');
      try {
        final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    //print('🔐 LOGIN RESPONSE: ${response.statusCode}');
    
    final token = response.data['token'] as String;
    await _storage.writeToken(token);
    //print('🔐 TOKEN SAVED');

    final user = _decodeUser(token);
    _authController.add(user);
    print('🔐 USER BROADCASTED: ${user.email}');

  } on DioException catch (e) {
    print('🔐 LOGIN ERROR: ${e.message}');
    final msg = e.response?.data?['message'] ?? 'Login failed';
    throw AuthException('invalid-credential', msg);
  }
}

  //REGISTER 
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      final token = response.data['token'] as String;
      await _storage.writeToken(token);
      _authController.add(_decodeUser(token));

    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registration failed';
      // 409 Conflict = email already exists (from our API)
      if (e.response?.statusCode == 409) {
        throw AuthException('email-already-in-use', msg);
      }
      throw AuthException('invalid-credential', msg);
    }
  }

  //LOGOUT
  Future<void> signOut() async {
    await _storage.deleteToken();
    _authController.add(null); //Broadcast "no user" → go_router redirects to login
  }

  // This method exists for API consistency but we use the stream instead.
  User? get currentUser => null;
}











/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  AuthRepository(this._auth);

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

// This provider makes the repository available anywhere in the app.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});*/