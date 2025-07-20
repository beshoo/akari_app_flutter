import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CustomFAB extends StatefulWidget {
  final Function()? onAddApartment;
  final Function()? onAddShare;

  const CustomFAB({
    super.key,
    this.onAddApartment,
    this.onAddShare,
  });

  @override
  State<CustomFAB> createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  bool _isOpen = false;
  
  // AutoSizeGroup to sync font sizes across menu items
  final AutoSizeGroup _menuItemsGroup = AutoSizeGroup();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    
    // Add slide animation for bottom-to-top movement
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from bottom (below visible area)
      end: const Offset(0, 0),   // End at normal position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFAB() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Dark overlay with fade animation
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _isOpen ? 0.75 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_isOpen,
                child: GestureDetector(
                  onTap: _toggleFAB,
                  child: Container(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // Menu items - positioned with proper constraints
          Positioned(
            left: 16,
            right: 16,
            bottom: 190,
            child: IgnorePointer(
              ignoring: !_isOpen && _controller.isDismissed,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    label: 'إضافة إعلان عن عقار',
                    onTap: widget.onAddApartment,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.trending_up,
                    label: 'إضافة إعلان عن أسهم تنظيمية',
                    onTap: widget.onAddShare,
                  ),
                ],
              ),
            ),
          ),

          // Main FAB - positioned with proper constraints
          Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FloatingActionButton.extended(
                onPressed: _toggleFAB,
                backgroundColor: const Color(0xFF8E6756),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AutoSizeText(
                        'أضف إعلانك الأن',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        minFontSize: 12,
                        maxFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isOpen ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Function()? onTap,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _animation,
        child: GestureDetector(
          onTap: () {
            _toggleFAB(); // Close the menu when an item is selected
            onTap?.call(); // Call the provided callback
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AutoSizeText(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    group: _menuItemsGroup,
                    maxLines: 1,
                    minFontSize: 12,
                    maxFontSize: 19,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16), // Reduced space between text and icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Color(0xFF8E6756),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 