import 'package:bsm_app/features/products/presentation/screens/products_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../scanner/data/product_repository.dart';
import '../../../scanner/domain/product_entity.dart';

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductEntity?, int>((ref, productId) {
  return ref.watch(productRepositoryProvider).getProductById(productId);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(ProductEntity original) async {
    if (_nameController.text == (original.productName ?? '') &&
        _notesController.text == (original.notes ?? '')) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);

    final updated = original.copyWith(
      productName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref.read(productRepositoryProvider).updateProduct(updated);
      ref.invalidate(userProductsProvider);
      setState(() => _isEditing = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(productRepositoryProvider).deleteProduct(widget.productId);
    ref.invalidate(userProductsProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Product Details'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        // ─── BACK BUTTON ───
        // Arrow icon that navigates back to the product list (/home)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to list',
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final product = productAsync.asData?.value;
                if (product != null) {
                  _nameController.text = product.productName ?? '';
                  _notesController.text = product.notes ?? '';
                }
                setState(() => _isEditing = true);
              },
            )
          else
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              onPressed: _isSaving
                  ? null
                  : () {
                      final product = productAsync.asData?.value;
                      if (product != null) _saveChanges(product);
                    },
            ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(Icons.qr_code, 'Barcode', product.barcode),
                const SizedBox(height: 16),
                _buildInfoCard(Icons.category, 'Type', product.barcodeType),
                const SizedBox(height: 16),
                _buildInfoCard(
                  Icons.calendar_today,
                  'Scanned On',
                  DateFormat('MMMM d, yyyy - h:mm a').format(product.scannedAt),
                ),
                const SizedBox(height: 24),

                _isEditing
                    ? TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      )
                    : _buildInfoCard(
                        Icons.label,
                        'Product Name',
                        product.productName ?? 'Not set',
                        isPlaceholder: product.productName == null,
                      ),
                const SizedBox(height: 16),

                _isEditing
                    ? TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 4,
                      )
                    : _buildInfoCard(
                        Icons.notes,
                        'Notes',
                        product.notes ?? 'No notes added',
                        isPlaceholder: product.notes == null,
                      ),
                const SizedBox(height: 32),

                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deleteProduct,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value, {
    bool isPlaceholder = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A73E8)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPlaceholder ? Colors.grey : Colors.black87,
                      fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}