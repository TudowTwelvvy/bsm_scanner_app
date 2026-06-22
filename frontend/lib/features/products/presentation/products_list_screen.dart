import 'package:bsm_scanner_app/features/auth/data/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../scanner/data/product_repository.dart';
import '../../scanner/domain/product_entity.dart';

/*class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scans'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),

      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('scans')
            .orderBy('scannedAt', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final scans = snapshot.data?.docs ?? [];

          if (scans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No scans yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the button below to scan your first barcode.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ListView.builder efficiently builds the list of scans. Each item is a Card with a ListTile showing the barcode, type, and timestamp.
          return ListView.builder(
            itemCount: scans.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final data = scans[index].data() as Map<String, dynamic>;
              final timestamp = data['scannedAt'] as Timestamp?;
              final date = timestamp?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code, color: Color(0xFF1A73E8)),
                  ),
                  title: Text(
                    data['barcode'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${data['barcodeType'] ?? 'Unknown'} • ${_formatDate(date)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),

      //opens the ScannerScreen when pressed. The StreamBuilder will automatically update when the user returns from scanning, showing the new scan in the list.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigator.push slides the ScannerScreen on top.
          // When the user finishes scanning and presses the back button,
          // they return here — and the StreamBuilder has already updated!
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
      ),
    );
  }

  // Simple date formatter without needing extra packages.
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}*/

//autoDispose destroys the provider when the screen is no longer visible.
//When the user returns from the ScannerScreen, it re-creates and re-fetches.
//This gives us "pull to refresh" behavior automatically.

//Without autoDispose: The list never updates after scanning. The user would
//have to kill and reopen the app to see new scans.
final userProductsProvider = FutureProvider.autoDispose<List<ProductEntity>>((ref) {
  // FutureProvider (not StreamProvider) because REST APIs don't push real-time
  // updates like Firestore. We fetch once when the screen opens.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
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
            error: (_,_) => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No scans yet. Tap "Scan" to start!',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductTile(product: products[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
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
              const Text('Total Scans', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(Icons.bar_chart, size: 64, color: Colors.white30),
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
      //ValueKey works with any object type. Key() only accepts String.
      //Since product.id is int, ValueKey is required.
      key: ValueKey(product.id),
      //Background shown when swiping left
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,// Only allow left swipe
      onDismissed: (_) async {
        await ref.read(productRepositoryProvider).deleteProduct(product.id);
        //We don't manually refresh the list. autoDispose providers
        //will rebuild on next frame. But to be immediate:
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