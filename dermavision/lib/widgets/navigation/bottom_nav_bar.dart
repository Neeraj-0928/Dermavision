import 'package:flutter/material.dart';

/// A custom bottom navigation bar styled to match the DermaVision design.
///
/// Usage:
/// ```dart
/// BottomNavBar(
///   selectedIndex: _selectedIndex,
///   onItemTapped: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  static const Color _purple = Color(0xFF7B4DFF);
  static const Color _grey = Color(0xFFBBB8CC);
  static const Color _background = Color(0xFFFAF9FF);

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.document_scanner_rounded, label: 'Scan'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _background,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B4DFF).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated indicator dot above icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 4 : 0,
                          height: isSelected ? 4 : 0,
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: const BoxDecoration(
                            color: _purple,
                            shape: BoxShape.circle,
                          ),
                        ),

                        Icon(
                          item.icon,
                          size: 24,
                          color: isSelected ? _purple : _grey,
                        ),

                        const SizedBox(height: 3),

                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? _purple : _grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
