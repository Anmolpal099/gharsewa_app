import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';

/// @deprecated Analytics merged into the modern Explore dashboard.
class ProviderAnalyticsScreen extends StatelessWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(RouteConstants.providerDashboard);
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
