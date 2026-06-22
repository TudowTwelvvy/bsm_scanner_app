import 'package:equatable/equatable.dart';

// equatable lets us compare two ProductEntities with == operator.
// Without it, ProductEntity(a, b, c) == ProductEntity(a, b, c) returns FALSE
// because Dart compares object references by default, not field values.
class ProductEntity extends Equatable {
  final int id;              //SQL Server auto-increment int
  final String barcode;
  final String? productName;
  final String? notes;
  final String barcodeType;
  final DateTime scannedAt;
  final String userId;       //guid string from Identity

  const ProductEntity({
    required this.id,
    required this.barcode,
    this.productName,
    this.notes,
    required this.barcodeType,
    required this.scannedAt,
    required this.userId,
  });


  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] as int,
      barcode: map['barcode'] ?? '',
      productName: map['productName'],
      notes: map['notes'],
      barcodeType: map['barcodeType'] ?? 'UNKNOWN',
      // API returns ISO 8601 string: "2026-06-15T10:30:00Z"
      // DateTime.parse converts this to a Dart DateTime object.
      scannedAt: DateTime.parse(map['scannedAt']),
      userId: map['userId']?.toString() ?? '',
    );
  }

  // ─── TO JSON (Dart object → API request) ───
  // WHY: When creating a product, we DON'T send id or userId.
  // The API assigns id (auto-increment) and reads userId from the JWT.
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'productName': productName,
      'notes': notes,
      'barcodeType': barcodeType,
    };
  }

  // ─── COPY WITH ───
  // WHY: In Flutter, we NEVER mutate objects. We create NEW ones.
  // This is called immutability and prevents subtle bugs where
  // Riverpod doesn't detect changes because the reference didn't change.
  ProductEntity copyWith({
    int? id,
    String? barcode,
    String? productName,
    String? notes,
    String? barcodeType,
    DateTime? scannedAt,
    String? userId,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      notes: notes ?? this.notes,
      barcodeType: barcodeType ?? this.barcodeType,
      scannedAt: scannedAt ?? this.scannedAt,
      userId: userId ?? this.userId,
    );
  }

  // Equatable requires listing all fields that determine equality.
  @override
  List<Object?> get props => [id, barcode, productName, notes, scannedAt, userId];
}