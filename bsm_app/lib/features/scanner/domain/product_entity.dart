import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  /// SQL Server auto-increment integer. Assigned by the API, not us.
  final int id;
  final String barcode;
  final String? productName;
  final String? notes;
  final String barcodeType;
  final DateTime scannedAt;
  final String userId;

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

  
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'productName': productName,
      'notes': notes,
      'barcodeType': barcodeType,
    };
  }

  
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