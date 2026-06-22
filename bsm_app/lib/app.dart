import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider. When auth state changes, GoRouter rebuilds
    // and recalculates redirect logic automatically.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BSM Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Pass the GoRouter instance to MaterialApp.
      // This connects Flutter's navigation system to GoRouter's GPS logic.
      routerConfig: router,
    );
  }
}