import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/secure_storage_service.dart';


final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});


final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient.create(storage);
});