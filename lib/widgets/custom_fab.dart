import 'package:flutter/material.dart';

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
  bool _isOpen = false;

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
    return Stack(
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

        // Menu items
        if (_isOpen)
          Positioned(
            left: 16,
            right: 16,
            bottom: 190,
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

        // Main FAB - Always positioned at the same spot
        Positioned(
          left: 16,
          bottom: 90,
          child: FloatingActionButton.extended(
            onPressed: _toggleFAB,
            backgroundColor: const Color(0xFF8E6756),
            label: Row(
              children: [
                Text(
                  'أضف إعلانك الأن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 150),
                        offset: const Offset(0, 2),
                        blurRadius: 15,
                      ),
                    ],
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
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Function()? onTap,
  }) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: GestureDetector(
          onTap: () {
            _toggleFAB(); // Close the menu when an item is selected
            onTap?.call(); // Call the provided callback
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 30), // Space between text and icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    color: Color(0xFF8E6756),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
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