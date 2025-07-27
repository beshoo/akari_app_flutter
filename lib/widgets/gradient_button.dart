import 'package:flutter/material.dart';

enum GradientDirection {
  topToBottom,
  leftToRight,
  topLeftToBottomRight,
  topRightToBottomLeft,
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final GradientDirection direction;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double width;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final Widget? icon;
  final double iconSpacing;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.colors = const [Color(0xFFA88B67), Color(0xFFA88B67), Color(0xFFC9B390)],
    this.direction = GradientDirection.topToBottom,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 50.0,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.icon,
    this.iconSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || onPressed == null || isLoading;
    
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: isButtonDisabled 
              ? colors.map((color) => color.withValues(alpha: 0.5)).toList()
              : colors,
          begin: _getGradientBegin(),
          end: _getGradientEnd(),
        ),
        boxShadow: isButtonDisabled ? null : [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textStyle?.color ?? Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: iconSpacing),
                ] else if (icon != null) ...[
                  icon!,
                  SizedBox(width: iconSpacing),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: (textStyle ?? const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    )).copyWith(
                      color: isButtonDisabled 
                          ? (textStyle?.color ?? Colors.white).withValues(alpha: 0.7)
                          : textStyle?.color ?? Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Alignment _getGradientBegin() {
    switch (direction) {
      case GradientDirection.topToBottom:
        return Alignment.topCenter;
      case GradientDirection.leftToRight:
        return Alignment.centerLeft;
      case GradientDirection.topLeftToBottomRight:
        return Alignment.topLeft;
      case GradientDirection.topRightToBottomLeft:
        return Alignment.topRight;
    }
  }

  Alignment _getGradientEnd() {
    switch (direction) {
      case GradientDirection.topToBottom:
        return Alignment.bottomCenter;
      case GradientDirection.leftToRight:
        return Alignment.centerRight;
      case GradientDirection.topLeftToBottomRight:
        return Alignment.bottomRight;
      case GradientDirection.topRightToBottomLeft:
        return Alignment.bottomLeft;
    }
  }
} 