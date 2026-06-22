import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/product_entity.dart';

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  //  CREATE 
  /// POST /api/product
  /// The API reads UserId from the JWT token automatically.
  /// We only send the product data, not who owns it.
  Future<void> saveProduct(ProductEntity product) async {
    await _dio.post('/api/product', data: product.toMap());
  }

  // READ ONE 
  /// GET /api/product/{id}
  /// Returns the product if found and belongs to this user.
  /// Returns null if 404 (not found or doesn't belong to user).
  Future<ProductEntity?> getProductById(int productId) async {
    try {
      final response = await _dio.get('/api/product/$productId');
      return ProductEntity.fromMap(response.data);
    } on DioException catch (e) {
      // 404 = product not found or doesn't belong to this user
      if (e.response?.statusCode == 404) return null;
      rethrow; // Let the caller handle unexpected errors
    }
  }

  // READ ALL
  /// GET /api/product
  /// Returns all scans for the currently logged-in user.
  /// The API reads UserId from the JWT.
  Future<List<ProductEntity>> fetchProducts() async {
    final response = await _dio.get('/api/product');
    final List<dynamic> data = response.data;
    // .map() transforms each JSON object into a ProductEntity.
    // .toList() converts the Iterable back into a List.
    return data.map((json) => ProductEntity.fromMap(json)).toList();
  }

  //  UPDATE 
  /// PUT /api/product/{id}
  /// Only sends productName and notes — these are the editable fields.
  Future<void> updateProduct(ProductEntity product) async {
    await _dio.put('/api/product/${product.id}', data: {
      'productName': product.productName,
      'notes': product.notes,
    });
  }

  //  DELETE
  /// DELETE /api/product/{id}
  Future<void> deleteProduct(int productId) async {
    await _dio.delete('/api/product/$productId');
  }

  //  COUNT 
  /// GET /api/product/count
  /// Returns the total number of scans for this user.
  Future<int> fetchCount() async {
    final response = await _dio.get('/api/product/count');
    return response.data as int;
  }
}


final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});