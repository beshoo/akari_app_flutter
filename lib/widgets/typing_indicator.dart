import 'package:flutter/material.dart';
import 'dart:math' as math;

class TypingIndicator extends StatefulWidget {
  final Color backgroundColor;
  final Color dotColor;
  final double dotSize;
  final Duration animationDuration;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const TypingIndicator({
    super.key,
    this.backgroundColor = const Color(0xFFe1e4ea),
    this.dotColor = const Color(0xFF9e9e9e),
    this.dotSize = 6.0,
    this.animationDuration = const Duration(milliseconds: 500),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.margin = const EdgeInsets.only(right: 8, bottom: 8),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    _opacityAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _animationControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Align to right for RTL
        children: [
          Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), // Sharp corner on right side
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: Listenable.merge([
                    _scaleAnimations[index],
                    _opacityAnimations[index],
                  ]),
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(
                        left: index < 2 ? 4 : 0, // RTL: left spacing between dots
                      ),
                      child: Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: Container(
                          width: widget.dotSize,
                          height: widget.dotSize,
                          decoration: BoxDecoration(
                            color: widget.dotColor.withValues(
                              alpha: (1.0 - _opacityAnimations[index].value).clamp(0.0, 1.0),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative minimal typing indicator for smaller spaces
class MinimalTypingIndicator extends StatefulWidget {
  final Color dotColor;
  final double dotSize;

  const MinimalTypingIndicator({
    Key? key,
    this.dotColor = const Color(0xFF9e9e9e),
    this.dotSize = 4.0,
  }) : super(key: key);

  @override
  State<MinimalTypingIndicator> createState() => _MinimalTypingIndicatorState();
}

class _MinimalTypingIndicatorState extends State<MinimalTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final progress = (_animation.value - delay).clamp(0.0, 1.0);
            final opacity = (math.sin(progress * math.pi)).clamp(0.3, 1.0);

            return Container(
              margin: EdgeInsets.only(left: index < 2 ? 3 : 0),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: widget.dotColor.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
} 