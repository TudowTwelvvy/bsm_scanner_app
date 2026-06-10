import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/product_entity.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  ProductRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _userProducts(String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .collection(FirestorePaths.products);
  }

  Future<void> saveProduct(ProductEntity product) async {
    await _userProducts(product.userId)
        .doc(product.id)
        .set(product.toMap());
  }

  //Stream = real-time. Firestore pushes updates to the UI automatically.
  Stream<List<ProductEntity>> watchUserProducts(String userId) {
    return _userProducts(userId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductEntity.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<int> watchScanCount(String userId) {
    return _userProducts(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> deleteProduct(String userId, String productId) async {
    await _userProducts(userId).doc(productId).delete();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreProvider));
});