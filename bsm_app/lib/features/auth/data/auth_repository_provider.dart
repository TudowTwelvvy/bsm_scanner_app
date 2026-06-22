import 'package:bsm_app/features/auth/domain/entities/user.dart';
import 'package:bsm_app/features/auth/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import 'auth_repository.dart';
 
//ref.watch(dioProvider) gets the HTTP client from Phase 2.
//ref.watch(secureStorageProvider) gets the encrypted vault from Phase 2.
//AuthRepository combines them to talk to your ASP.NET API.
final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});