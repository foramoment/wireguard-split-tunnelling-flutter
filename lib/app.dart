import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Main application widget
class WgClientApp extends ConsumerWidget {
  const WgClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch theme provider for theme switching
    final isDarkMode = false; // Will be replaced with provider

    return MaterialApp.router(
      title: 'WireGuard Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
