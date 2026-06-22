class AppConstants {
  
  AppConstants._();

  static const String apiBaseUrl = 'http://10.0.0.158:5230';
  
  static const Duration apiTimeout = Duration(seconds: 10);

  //App info
  static const String appName = 'BSM Scanner';
  static const String appVersion = '1.0.0';

  //Storage Keys .
  static const String tokenKey = 'jwt_token';
}