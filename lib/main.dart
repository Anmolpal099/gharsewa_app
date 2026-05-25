import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/env_config.dart';
import 'core/theme/theme_provider.dart';
import 'data/datasources/local/cache_manager.dart' as app_cache;
import 'data/datasources/local/hive_adapters.dart';
import 'data/datasources/local/local_storage_service.dart';
import 'features/provider_panel/data/services/cache_manager.dart' as provider_cache;
import 'presentation/router/app_router.dart';
import 'services/auth/auth_service.dart';
import 'services/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print env config in debug mode
  EnvConfig.printConfig();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters for data models
  registerHiveAdapters();
  
  // Initialize local storage service
  await LocalStorageService.initialize();
  
  // Open legacy boxes (for backward compatibility)
  await Hive.openBox('settings');

  // Provider panel offline cache (Safety SOPs, profile)
  await provider_cache.initializeProviderPanelCache();
  await Hive.openBox('dismissed_suggestions');

  await NotificationService().initialize();

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
    final theme = ref.watch(appThemeProvider);

    ref.listen(authServiceProvider, (prev, next) {
      final wasAuthed = prev?.value?.isAuthenticated ?? false;
      final isAuthed = next.value?.isAuthenticated ?? false;
      if (!wasAuthed && isAuthed) {
        ref.read(app_cache.cacheManagerProvider).syncAll();
      }
    });

    return MaterialApp.router(
      title: 'Gharsewa',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
