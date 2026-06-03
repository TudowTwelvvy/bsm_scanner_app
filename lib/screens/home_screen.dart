import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatelessWidget {
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
}