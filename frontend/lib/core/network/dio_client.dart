import 'package:dio/dio.dart';
import 'auth_events.dart';
import '../services/secure_storage_service.dart';

class DioClient {
  //Factory method pattern. Instead of calling 'new Dio()' everywhere,
  //we centralize configuration. If we need to change the base URL or add
  //a new header, we change it in ONE place.
  static Dio create(SecureStorageService storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.0.158:5230',
        //baseUrl: 'http://192.168.0.104:5230',
        //baseUrl: 'http://192.168.137.1:5230',

        // If the API doesn't respond in 10 seconds, abort.
        // Prevents the app from hanging indefinitely on a dead server.
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),

        // Every request sends these headers automatically.
        // Content-Type tells the API we're sending JSON.
        // Accept tells the API we want JSON back.
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    //Interceptors run BEFORE the request leaves the app.
    //We attach the token here so EVERY request is authenticated
    //without manually adding headers in every repository method.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();

        // If we have a token, attach it. If not, send the request anyway
        // (the API will return 401 for protected endpoints).
        if (token != null) {
          // Bearer is the OAuth 2.0 standard prefix. The API expects:
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
          // Emit a global event. AuthRepository is listening and will
          // clear the token and broadcast "user logged out" to all screens.
          AuthEvents.emitUnauthorized();
        }

        // Continue propagating the error so the calling code can show
        // a SnackBar or dialog to the user.
        handler.next(error);
      },
    ));

    //During development, you need to see exactly what JSON is
    //sent and received. In production, remove this to avoid leaking
    //sensitive data (tokens, passwords) to logs.
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  }
}