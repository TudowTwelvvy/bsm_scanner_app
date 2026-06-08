import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String barcode;
  final String? productName;
  final String barcodeType;
  final DateTime scannedAt;
  final String userId;

  const ProductEntity({
    required this.id,
    required this.barcode,
    this.productName,
    required this.barcodeType,
    required this.scannedAt,
    required this.userId,
  });

  //fromMap converts Firestore JSON into our clean object.
  factory ProductEntity.fromMap(String id, Map<String, dynamic> map) {
    return ProductEntity(
      id: id,
      barcode: map['barcode'] ?? '',
      productName: map['productName'],
      barcodeType: map['barcodeType'] ?? 'UNKNOWN',
      scannedAt: (map['scannedAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  //toMap converts our object back into JSON for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'productName': productName,
      'barcodeType': barcodeType,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'userId': userId,
    };
  }

  @override
  List<Object?> get props => [id, barcode, scannedAt, userId];
}