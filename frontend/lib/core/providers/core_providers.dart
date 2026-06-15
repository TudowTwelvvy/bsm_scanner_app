import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/secure_storage_service.dart';

// WHY: Provider creates a SINGLE instance that is shared across the app.
// If we used 'final storage = SecureStorageService()' inside widgets,
// we'd create multiple instances. Provider guarantees one.

// SecureStorage is stateless (no internal state changes), so we use plain Provider.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Dio depends on SecureStorage (to read the token), so we watch it.
// If SecureStorage were ever replaced, Dio would rebuild. It won't,
// but this is the correct dependency pattern.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient.create(storage);
});