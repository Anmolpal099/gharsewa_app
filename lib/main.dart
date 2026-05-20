import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print env config in debug mode
  EnvConfig.printConfig();

  // Initialize Firebase
  await FirebaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: GharsewaApp(),
    ),
  );
}

class GharsewaApp extends ConsumerWidget {
  const GharsewaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authAsync = ref.watch(authServiceProvider);

    // Determine theme based on auth role
    final theme = authAsync.when(
      data: (auth) {
        switch (auth.role) {
          case UserRole.serviceProvider: return AppTheme.providerTheme;
          case UserRole.admin:           return AppTheme.adminTheme;
          default:                       return AppTheme.customerTheme;
        }
      },
      loading: () => AppTheme.customerTheme,
      error: (_, __) => AppTheme.customerTheme,
    );

    return MaterialApp.router(
      title: 'Gharsewa',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
