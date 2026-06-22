import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/product_entity.dart';

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  //create
  //POST /api/product
  //the API reads UserId from the JWT token automatically.
  //We only send the product data, not who owns it.
  Future<void> saveProduct(ProductEntity product) async {
    await _dio.post('/api/product', data: product.toMap());
  }

  //Get 1
  // GET /api/product/{id}
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

  //Get all
  // GET /api/product
  // Returns List<dynamic> which we map to List<ProductEntity>
  Future<List<ProductEntity>> fetchProducts() async {
    final response = await _dio.get('/api/product');
    final List<dynamic> data = response.data;
    return data.map((json) => ProductEntity.fromMap(json)).toList();
  }

  //update
  // PUT /api/product/{id}
  Future<void> updateProduct(ProductEntity product) async {
    await _dio.put('/api/product/${product.id}', data: {
      'productName': product.productName,
      'notes': product.notes,
    });
  }

  //delete
  // DELETE /api/product/{id}
  Future<void> deleteProduct(int productId) async {
    await _dio.delete('/api/product/$productId');
  }

  //count
  // GET /api/product/count
  Future<int> fetchCount() async {
    final response = await _dio.get('/api/product/count');
    return response.data as int;
  }
}

// WHY: Provider makes the repository available via ref.watch/read.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});