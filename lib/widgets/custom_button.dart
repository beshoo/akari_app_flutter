import 'package:flutter/material.dart';

enum GradientDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool hasGradient;
  final bool isLoading;
  final bool isDisabled;
  final List<Color>? gradientColors;
  final GradientDirection gradientDirection;
  final Color? textColor;
  final Color? borderColor;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;

  const CustomButton({
    super.key,
    required this.title,
    this.onPressed,
    this.hasGradient = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradientColors,
    this.gradientDirection = GradientDirection.leftToRight,
    this.textColor,
    this.borderColor,
    this.height = 40,
    this.borderRadius = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = isDisabled || isLoading;
    final opacity = isPressed ? 0.5 : 1.0;

    return Expanded(
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: hasGradient ? _buildGradient() : null,
            border: !hasGradient
                ? Border.all(
                    color: borderColor ?? const Color(0xff4b5563),
                    width: 1,
                  )
                : null,
            color: !hasGradient ? Colors.transparent : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPressed ? null : onPressed,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                                              : Text(
                          title,
                          style: TextStyle(
                            color: _getTextColor(),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _buildGradient() {
    final colors = gradientColors ?? [
      const Color(0xff633e3d),
      const Color(0xff774b46),
      const Color(0xff8d5e52),
      const Color(0xffa47764),
      const Color(0xffbda28c),
    ];

    AlignmentGeometry begin;
    AlignmentGeometry end;

    switch (gradientDirection) {
      case GradientDirection.leftToRight:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case GradientDirection.rightToLeft:
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
      case GradientDirection.topToBottom:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case GradientDirection.bottomToTop:
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
    );
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    return hasGradient ? Colors.white : const Color(0xff4b5563);
  }
} 