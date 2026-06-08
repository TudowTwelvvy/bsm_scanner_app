import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/firebase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/products/presentation/products_list_screen.dart';
import '../features/scanner/presentation/scanner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state. When login/logout happens, the router rebuilds.
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/home',
    // redirect = the security guard. Runs BEFORE every navigation.
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.uri.path == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null; // null = proceed normally
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
    ],
  );
});