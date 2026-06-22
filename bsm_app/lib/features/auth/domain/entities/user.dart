class User {
  final String id;
  final String email;
  final String? displayName;
  final List<String> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.roles = const [], // const [] is a Dart trick for "empty list by default"
    required this.createdAt,
  });

  
  bool hasRole(String role) => roles.contains(role);

  
  bool get isAdmin => hasRole('Admin');

  @override
  String toString() {
    return 'User(id: $id, email: $email, roles: $roles)';
  }
}