//port 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/data/auth_repository_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/products_list_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import '../splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.asData?.value != null;
      final isLoginRoute = state.uri.path == '/login';
      final isRegisterRoute = state.uri.path == '/register';
      final isSplashRoute = state.uri.path == '/splash';

      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute && !isSplashRoute) {
        return '/login';
      }

      if (isLoggedIn && (isLoginRoute || isRegisterRoute || isSplashRoute)) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ProductsListScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      // ─── UPDATED: Real Product Detail Screen ───
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          // Path parameters are ALWAYS strings in URLs.
          // We parse to int for our API (SQL Server uses int IDs).
          final productId = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: productId);
        },
      ),
    ],
  );
});