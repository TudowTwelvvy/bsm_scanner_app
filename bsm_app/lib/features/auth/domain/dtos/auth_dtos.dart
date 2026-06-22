class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  @override
  String toString() => 'LoginRequest(email: $email, password: ***)';
}

class RegisterRequest {
  final String email;
  final String password;
  final String? displayName;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'displayName': displayName,
      };

  @override
  String toString() => 'RegisterRequest(email: $email, displayName: $displayName)';
}


class AuthResponse {
  final String token;
  final Map<String, dynamic>? user;

  const AuthResponse({
    required this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'AuthResponse(token: ${token.substring(0, 20)}...)';
}