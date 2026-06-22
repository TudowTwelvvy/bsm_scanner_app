import 'package:jwt_decoder/jwt_decoder.dart';
import '../entities/user.dart';

class JwtParser {
  JwtParser._(); // Private constructor — we only use static methods.

  static User? decodeUser(String token) {
    // JwtDecoder.isExpired checks the 'exp' claim using pure math.
    // No network request needed — it compares the expiry timestamp to now().
    if (JwtDecoder.isExpired(token)) {
      return null; // Passport expired — throw it away.
    }

    // Decode the payload (middle section) into a Map.
    final decoded = JwtDecoder.decode(token);

 
    // In ASP.NET Identity, this is the Guid string.
    final id = decoded['sub'] as String?;
    final email = decoded['email'] as String?;

    // If the token is missing critical info, it's invalid.
    if (id == null || email == null) {
      return null;
    }

    final roles = _parseRoles(decoded['role']);

    return User(
      id: id,
      email: email,
      displayName: decoded['name'] as String?,
      roles: roles,
      createdAt: DateTime.now(),
    );
  }

  //Checks if a token is expired without decoding the full user
  static bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  
  static List<String> _parseRoles(dynamic roleClaim) {
    if (roleClaim == null) {
      return ['User']; // Default role if API doesn't send one.
    }
    if (roleClaim is List) {
      // .cast<String>() converts List<dynamic> to List<String>.
      return roleClaim.cast<String>();
    }
    // Single string role — wrap it in a list.
    return [roleClaim.toString()];
  }
}