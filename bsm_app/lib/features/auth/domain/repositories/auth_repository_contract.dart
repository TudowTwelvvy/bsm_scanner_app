import '../dtos/auth_dtos.dart';
import '../entities/user.dart';


abstract class AuthRepositoryContract {
  
  Stream<User?> get authStateChanges;

  User? get currentUser;

  
  Future<void> signInWithEmail(LoginRequest request);

  
  Future<void> registerWithEmail(RegisterRequest request);

  
  Future<void> signOut();
}