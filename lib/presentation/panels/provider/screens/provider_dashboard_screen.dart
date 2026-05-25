import 'package:flutter/material.dart';

import '../../../../features/provider_panel/presentation/screens/modern_dashboard_screen.dart';

/// @deprecated Use [ModernDashboardScreen] via [ProviderPanelRoot] / go_router.
class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const ModernDashboardScreen();
}
