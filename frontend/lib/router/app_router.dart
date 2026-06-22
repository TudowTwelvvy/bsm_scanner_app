// lib/router/app_router.dart
import 'dart:async';

import 'package:bsm_scanner_app/features/auth/domain/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/products_list_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Stream<User?> authStream) {
    _subscription = authStream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // FIXED: Riverpod 3.x removed .stream on StreamProvider.
  // Get the stream directly from the AuthRepository instead.
  final authRepo = ref.watch(authRepositoryProvider);
  final authStream = authRepo.authStateChanges;
  
  final authRefresh = AuthRefreshListenable(authStream);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authRefresh,

    redirect: (context, state) {
      // Use ref.read to get the current AsyncValue without watching
      final authState = ref.read(authStateChangesProvider);
      
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.uri.path == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ProductsListScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: productId);
        },
      ),
    ],
  );
});