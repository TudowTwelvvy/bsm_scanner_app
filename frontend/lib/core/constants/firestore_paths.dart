class FirestorePaths {
  static const String users = 'users';
  static const String products = 'products';

  static String userProducts(String userId) => 'users/$userId/$products';
}