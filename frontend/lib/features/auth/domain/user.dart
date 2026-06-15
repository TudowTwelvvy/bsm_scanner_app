class User {
  final int id;           // Was String uid in Firebase... API uses int.
  final String email;
  final String? displayName;
  final List<String> roles; // NEW: Identity supports roles (User, Admin, etc.)
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.roles = const [], // Default to empty list if API doesn't send roles
    required this.createdAt,
  });
}