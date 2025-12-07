import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/tunnel_details/tunnel_details_screen.dart';
import '../../screens/add_tunnel/add_tunnel_screen.dart';
import '../../screens/import_tunnel/import_tunnel_screen.dart';
import '../../screens/split_tunneling/split_tunneling_screen.dart';
import '../../screens/settings/settings_screen.dart';

/// App route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String tunnelDetails = '/tunnel/:id';
  static const String addTunnel = '/tunnel/add';
  static const String editTunnel = '/tunnel/:id/edit';
  static const String importTunnel = '/import';
  static const String splitTunneling = '/tunnel/:id/split-tunneling';
  static const String settings = '/settings';
}

/// GoRouter configuration for the app
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.tunnelDetails,
      name: 'tunnel-details',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TunnelDetailsScreen(tunnelId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.addTunnel,
      name: 'add-tunnel',
      builder: (context, state) => const AddTunnelScreen(),
    ),
    GoRoute(
      path: AppRoutes.editTunnel,
      name: 'edit-tunnel',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddTunnelScreen(tunnelId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.importTunnel,
      name: 'import-tunnel',
      builder: (context, state) => const ImportTunnelScreen(),
    ),
    GoRoute(
      path: AppRoutes.splitTunneling,
      name: 'split-tunneling',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SplitTunnelingScreen(tunnelId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
