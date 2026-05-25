import 'package:flutter/material.dart';
import '../../business_logic/admin_navigation_controller.dart';

/// Responsive admin sidebar (expanded on wide web layouts).
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.extended,
    required this.onNavigate,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1A237E);

    return Material(
      color: brandColor,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 32),
                if (extended) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'GharSewa Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: AdminNavigationController.items.length,
              itemBuilder: (context, index) {
                final item = AdminNavigationController.items[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    leading: Icon(
                      _iconForIndex(item.iconIndex),
                      color: selected ? brandColor : Colors.white70,
                    ),
                    title: extended
                        ? Text(
                            item.label,
                            style: TextStyle(
                              color: selected ? brandColor : Colors.white,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor:
                        selected ? Colors.white : Colors.transparent,
                    onTap: () => onNavigate(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _iconForIndex(int index) {
    switch (index) {
      case 1:
        return Icons.people_outline;
      case 2:
        return Icons.calendar_month_outlined;
      case 3:
        return Icons.assessment_outlined;
      case 4:
        return Icons.person_outline;
      default:
        return Icons.dashboard_outlined;
    }
  }
}
