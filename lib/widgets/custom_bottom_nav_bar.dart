import 'package:flutter/material.dart';

/// Model class for bottom navigation items
class BottomNavItem {
  final String label;
  final String inactiveIcon;
  final String activeIcon;
  final String route;

  const BottomNavItem({
    required this.label,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.route,
  });
}

/// Default navigation items used in the app
class DefaultNavItems {
  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'الرئيسية',
      inactiveIcon: 'assets/images/icons/home_screen_unactive.png',
      activeIcon: 'assets/images/icons/home_screen_active.png',
      route: '/home',
    ),
    BottomNavItem(
      label: 'المواعيد',
      inactiveIcon: 'assets/images/icons/myposts_unactive.png',
      activeIcon: 'assets/images/icons/myposts_active.png',
      route: '/appointments',
    ),
    BottomNavItem(
      label: 'إعلاناتي',
      inactiveIcon: 'assets/images/icons/order_screen_unactive.png',
      activeIcon: 'assets/images/icons/order_screen_active.png',
      route: '/my-posts',
    ),
    BottomNavItem(
      label: 'المقاسم',
      inactiveIcon: 'assets/images/icons/sector_screen_unactive.png',
      activeIcon: 'assets/images/icons/sector_screen_active.png',
      route: '/sectors',
    ),
    BottomNavItem(
      label: 'المزيد',
      inactiveIcon: 'assets/images/icons/menu_screen_unactive.png',
      activeIcon: 'assets/images/icons/menu_screen_active.png',
      route: '/more',
    ),
  ];
}

class _CustomNavBarShape extends ShapeBorder {
  const _CustomNavBarShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

/// A custom bottom navigation bar with a floating design and curved edges.
///
/// This widget creates a bottom navigation bar that appears to float above the content
/// with rounded corners and a shadow effect. It supports both icon and label customization
/// and maintains the app's design language.
///
/// Example usage:
/// ```dart
/// CustomBottomNavBar(
///   currentIndex: _selectedIndex,
///   onTap: (index) => setState(() => _selectedIndex = index),
///   items: DefaultNavItems.items, // Or provide your own items
/// )
/// ```
class CustomBottomNavBar extends StatelessWidget {
  /// The current selected index in the navigation bar
  final int currentIndex;

  /// Callback function when an item is tapped
  final Function(int) onTap;

  /// List of navigation items to display
  final List<BottomNavItem> items;

  /// Background color of the navigation bar
  final Color backgroundColor;

  /// Color of the selected item
  final Color selectedItemColor;

  /// Color of unselected items
  final Color unselectedItemColor;

  /// Font size for the labels
  final double labelFontSize;

  /// Shadow color for the floating effect
  final Color shadowColor;

  /// Shadow opacity for the floating effect
  final double shadowOpacity;

  /// Margin around the navigation bar
  final EdgeInsets margin;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = DefaultNavItems.items,
    this.backgroundColor = const Color(0xFFEAE2DB),
    this.selectedItemColor = const Color(0xFFa47764),
    this.unselectedItemColor = const Color(0xFF71717a),
    this.labelFontSize = 12,
    this.shadowColor = Colors.black,
    this.shadowOpacity = 0.1,
    this.margin = const EdgeInsets.fromLTRB(15, 0, 15, 15),
  });

  @override
  Widget build(BuildContext context) {
    // Get safe area padding for proper positioning across platforms
    final double bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    
    // Adjust bottom margin to account for safe area
    final adjustedMargin = EdgeInsets.fromLTRB(
      margin.left,
      margin.top,
      margin.right,
      margin.bottom + bottomSafeArea,
    );
    
    return Padding(
      padding: adjustedMargin,
      child: PhysicalShape(
        color: backgroundColor,
        shadowColor: shadowColor,
        elevation: 8,
        clipper: ShapeBorderClipper(
          shape: const _CustomNavBarShape(),
        ),
        child: Material(
          color: Colors.transparent,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: selectedItemColor,
            unselectedItemColor: unselectedItemColor,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(
              fontSize: labelFontSize,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: labelFontSize,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
            ),
            items: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isSelected = currentIndex == entry.key;
              return _buildNavItem(
                item.label,
                item.inactiveIcon,
                item.activeIcon,
                isSelected,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String label,
    String inactiveIcon,
    String activeIcon,
    bool isSelected,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Image.asset(
          isSelected ? activeIcon : inactiveIcon,
          width: 24,
          height: 24,
          color: isSelected ? selectedItemColor : unselectedItemColor,
        ),
      ),
      label: label,
    );
  }
} 