
enum Environment {
  dev,   //Development
  prod,  //Production
}

class EnvironmentConfig {
  EnvironmentConfig._();

  // Change environments below
  static const Environment current = Environment.dev;

  /// The API base URL changes based on environment.
  /// In dev: we talk to the local ASP.NET API on your computer.
  /// In prod: we talk to your deployed API on the internet.
  static String get apiBaseUrl {
    switch (current) {
      case Environment.dev:
        return 'http://10.0.2.2:5230';
      case Environment.prod:
        return 'https://api.scannerpro.com'; // Change this when you deploy
    }
  }

  //In development, we show detailed HTTP request/response logs.
  //In production, we hide them to protect sensitive data (passwords, tokens).
  static bool get enableLogging => current == Environment.dev;

  //In development, we allow HTTP (not HTTPS) connections.
  //Android blocks HTTP by default for security — we only allow it during testing.
  static bool get allowHttp => current == Environment.dev;
}