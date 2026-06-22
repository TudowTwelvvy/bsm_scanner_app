import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/auth_repository_provider.dart';
import '../../../scanner/data/product_repository.dart';
import '../../../scanner/domain/product_entity.dart';

final userProductsProvider = FutureProvider.autoDispose<List<ProductEntity>>((ref) {
  return ref.watch(productRepositoryProvider).fetchProducts();
});

final scanCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(productRepositoryProvider).fetchCount();
});

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(userProductsProvider);
    final countAsync = ref.watch(scanCountProvider);
    
    // Watch auth state to get current user for display name
    final authAsync = ref.watch(authStateChangesProvider);
    final user = authAsync.asData?.value;
    
    // Build greeting text: displayName > email prefix > fallback
    final String greeting = user != null
        ? 'Hello, ${user.displayName ?? user.email.split('@').first}'
        : 'Scan History';

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          countAsync.when(
            data: (count) => _buildCountCard(context, count),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userProductsProvider);
                ref.invalidate(scanCountProvider);
                await ref.read(userProductsProvider.future);
              },
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) => _ProductTile(product: products[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  error: error,
                  onRetry: () {
                    ref.invalidate(userProductsProvider);
                    ref.invalidate(scanCountProvider);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/scanner'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
      ),
    );
  }

  Widget _buildCountCard(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Scans',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.bar_chart, size: 64, color: Colors.white30),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No scans yet. Tap + to start!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final ProductEntity product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(product.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(productRepositoryProvider).deleteProduct(product.id);
        ref.invalidate(userProductsProvider);
        ref.invalidate(scanCountProvider);
      },
      child: ListTile(
        onTap: () => context.go('/product/${product.id}'),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.qr_code),
        ),
        title: Text(
          product.productName ?? product.barcode,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${product.barcodeType} · ${DateFormat('MMM d, h:mm a').format(product.scannedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}