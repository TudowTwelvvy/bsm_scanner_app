import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';
import 'auth_events.dart';


class DioClient {
  static Dio create(SecureStorageService storage) {
    final dio = Dio(
      BaseOptions(
        
        baseUrl: 'http://10.0.0.158:5230',

        
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),

        // Every request sends these headers automatically.
        // Content-Type tells the API that it is sending JSON."
        // Accept tells the API it wants JSON back."
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    //Attach JWT Token 
    // Interceptors run BEFORE the request leaves the app.
    // We attach the token here so EVERY request is authenticated
    // without manually adding headers in every repository method.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Read the token from secure storage (the encrypted vault).
        final token = await storage.readToken();

        // If we have a token, attach it. If not, send the request anyway
        // (the API will return 401 for protected endpoints).
        if (token != null) {
          // "Bearer" is the OAuth 2.0 standard prefix. The API expects:
          // Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
          options.headers['Authorization'] = 'Bearer $token';
        }

        // handler.next(options) continues the request.
        // handler.reject() would abort it.
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 = Unauthorized. The token is expired, invalid, or missing.
        // Instead of handling this in every screen, we centralize it here.
        if (error.response?.statusCode == 401) {
          // Emit a global event. AuthRepository (Phase 4) will be listening
          // and will clear the token + broadcast "user logged out" to all screens.
          AuthEvents.emitUnauthorized();
        }

        // Continue propagating the error so the calling code (repository)
        // can catch it and show a SnackBar or dialog to the user.
        handler.next(error);
      },
    ));

    // Request/Response Logging
    // During development, you need to see exactly what JSON is sent and received.
    // In production, we'll remove this to avoid leaking sensitive data
    // (tokens, passwords) to device logs.
    dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  }
}