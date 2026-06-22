import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import 'auth_repository.dart';
import '../domain/user.dart';


final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

//StreamProvider automatically rebuilds widgets when the stream emits. (.valueOrNull) gives us the current value (or null if loading).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});