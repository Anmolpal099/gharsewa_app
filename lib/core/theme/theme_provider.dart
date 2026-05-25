import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/panel_config.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_state.dart';
import 'app_theme.dart';

/// Riverpod theme management (Task 3.4.3).
final appThemeProvider = Provider<ThemeData>((ref) {
  final auth = ref.watch(authServiceProvider).value;
  return themeForRole(auth?.role ?? UserRole.customer);
});

final panelThemeProvider = Provider.family<ThemeData, PanelType>((ref, panel) {
  switch (panel) {
    case PanelType.customer:
      return AppTheme.customerTheme;
    case PanelType.provider:
      return AppTheme.providerTheme;
    case PanelType.admin:
      return AppTheme.adminTheme;
  }
});

ThemeData themeForRole(UserRole role) {
  switch (role) {
    case UserRole.serviceProvider:
      return AppTheme.providerTheme;
    case UserRole.admin:
      return AppTheme.adminTheme;
    default:
      return AppTheme.customerTheme;
  }
}
