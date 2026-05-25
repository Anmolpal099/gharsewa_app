import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/platform_config.dart';
import '../../data/models/panel_config.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_state.dart';

final panelManagerProvider = Provider<PanelManager>((ref) {
  return PanelManager(ref);
});

/// Manages panel lifecycle and switching (Tasks 3.3.1–3.3.3).
class PanelManager {
  PanelManager(this._ref);

  final Ref _ref;
  PanelType? _activePanel;

  PanelType? get activePanel => _activePanel;

  PanelConfig configFor(PanelType type) {
    switch (type) {
      case PanelType.customer:
        return PanelConfig.customer;
      case PanelType.provider:
        return PanelConfig.provider;
      case PanelType.admin:
        return PanelConfig.admin;
    }
  }

  PanelConfig configForRole(UserRole role) => PanelConfig.forRole(role);

  /// Whether the user can open a panel on this platform.
  bool canAccess(PanelType type) {
    final platform = PlatformConfig.current;
    if (type == PanelType.admin && !platform.supportsAdminPanel) {
      return false;
    }
    final auth = _ref.read(authServiceProvider).value;
    if (auth == null || !auth.isAuthenticated) return false;
    switch (type) {
      case PanelType.customer:
        return auth.user?.isCustomer ?? true;
      case PanelType.provider:
        return auth.user?.isServiceProvider ?? false;
      case PanelType.admin:
        return auth.user?.isAdmin ?? false;
    }
  }

  /// Switch active panel and return root route.
  String? switchTo(PanelType type) {
    if (!canAccess(type)) return null;
    disposePanel(_activePanel);
    _activePanel = type;
    return configFor(type).rootRoute;
  }

  void disposePanel(PanelType? type) {
    if (type == null) return;
    // Hook for clearing panel-scoped caches when switching.
    _activePanel = null;
  }

  void disposeAll() => disposePanel(_activePanel);
}
