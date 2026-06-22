import 'dart:async';
import 'package:bsm_app/features/auth/domain/dtos/auth_dtos.dart';
import 'package:bsm_app/features/auth/domain/entities/user.dart';
import 'package:bsm_app/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:bsm_app/features/auth/domain/repositories/auth_repository_contract.dart';
import 'package:bsm_app/features/auth/domain/services/jwt_parser.dart';
import 'package:dio/dio.dart';
import '../../../core/network/auth_events.dart';
import '../../../core/services/secure_storage_service.dart';


class AuthRepository implements AuthRepositoryContract {
  final Dio _dio;         // HTTP client from Phase 2
  final SecureStorageService _storage; // Encrypted vault from Phase 2

  final _authController = StreamController<User?>.broadcast();

  //keep track of the current user so get currentUser works synchronously.
  User? _currentUser;

  AuthRepository(this._dio, this._storage) {
    _init(); 
    AuthEvents.onUnauthorized.listen((_) => signOut());
  }
 
  @override
  Stream<User?> get authStateChanges => _authController.stream;

  
  @override
  User? get currentUser => _currentUser;

  //when it starts it check for existing token
  Future<void> _init() async {
    final token = await _storage.readToken();

    //JwtParser.isExpired checks the 'exp' claim using pure math.
    //No network request needed — it compares the expiry timestamp to now().
    if (token != null && !JwtParser.isTokenExpired(token)) {
      final user = JwtParser.decodeUser(token);
      _currentUser = user;
      _authController.add(user);
    } else {
      //Token missing or expired. Delete it to prevent sending stale tokens.
      await _storage.deleteToken();
      _currentUser = null;
      _authController.add(null); // null = no user logged in
    }
  }

  //LOGIN
  @override
  Future<void> signInWithEmail(LoginRequest request) async {
    try {
      
      final response = await _dio.post('/api/auth/login', data: request.toJson());

      
      final token = response.data['token'] as String;
      await _storage.writeToken(token);

      final user = JwtParser.decodeUser(token);
      _currentUser = user;

      _authController.add(user);

    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  //REGISTER
  @override
  Future<void> registerWithEmail(RegisterRequest request) async {
    try {
      final response = await _dio.post('/api/auth/register', data: request.toJson());

      final token = response.data['token'] as String;
      await _storage.writeToken(token);

      final user = JwtParser.decodeUser(token);
      _currentUser = user;
      _authController.add(user);

    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  //LOGOUT
  @override
  Future<void> signOut() async {
    await _storage.deleteToken();
    _currentUser = null;
    _authController.add(null); // Broadcast "no user" → go_router redirects to login
  }

  void _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message']?.toString().toLowerCase() ?? '';

    switch (statusCode) {
      case 401:
        // 401 = Unauthorized. Wrong email or password.
        throw InvalidCredentialException();
      case 409:
        // 409 = Conflict. Email already exists in database.
        throw EmailAlreadyInUseException();
      case 400:
        // 400 = Bad Request. Could be weak password or invalid data.
        if (message.contains('password') && 
            (message.contains('weak') || message.contains('short'))) {
          throw WeakPasswordException();
        }
        throw InvalidCredentialException();
      case 404:
        // 404 = Not Found. Email doesn't exist in database.
        throw UserNotFoundException();
      default:
        // 500, 502, 503, or any unexpected error.
        throw UnknownAuthException();
    }
  }
}