import 'package:flutter/material.dart';

class CustomRichText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;
  final double? height;
  final double? fontSize;
  final String? fontFamily;

  const CustomRichText({
    super.key,
    required this.text,
    this.baseStyle,
    this.textAlign,
    this.height,
    this.fontSize,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return _buildRichText(text);
  }

  Widget _buildRichText(String text) {
    final List<TextSpan> spans = [];
    
    final Map<String, TextStyle> tagStyles = {
      'b': TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily ?? baseStyle?.fontFamily ?? 'Cairo',
        fontSize: fontSize ?? baseStyle?.fontSize ?? 14,
        color: baseStyle?.color ?? const Color(0xFF1A1A1A),
        height: height ?? baseStyle?.height ?? 1.4,
      ),
      'i': TextStyle(
        fontStyle: FontStyle.italic,
        fontFamily: fontFamily ?? baseStyle?.fontFamily ?? 'Cairo',
        fontSize: fontSize ?? baseStyle?.fontSize ?? 14,
        color: baseStyle?.color ?? const Color(0xFF1A1A1A),
        height: height ?? baseStyle?.height ?? 1.4,
      ),
      'u': TextStyle(
        decoration: TextDecoration.underline,
        fontFamily: fontFamily ?? baseStyle?.fontFamily ?? 'Cairo',
        fontSize: fontSize ?? baseStyle?.fontSize ?? 14,
        color: baseStyle?.color ?? const Color(0xFF1A1A1A),
        height: height ?? baseStyle?.height ?? 1.4,
      ),
      'strong': TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily ?? baseStyle?.fontFamily ?? 'Cairo',
        fontSize: fontSize ?? baseStyle?.fontSize ?? 14,
        color: baseStyle?.color ?? const Color(0xFF1A1A1A),
        height: height ?? baseStyle?.height ?? 1.4,
      ),
      'em': TextStyle(
        fontStyle: FontStyle.italic,
        fontFamily: fontFamily ?? baseStyle?.fontFamily ?? 'Cairo',
        fontSize: fontSize ?? baseStyle?.fontSize ?? 14,
        color: baseStyle?.color ?? const Color(0xFF1A1A1A),
        height: height ?? baseStyle?.height ?? 1.4,
      ),
    };

    // Base style for normal text
    final baseTextStyle = baseStyle != null 
        ? baseStyle!.copyWith(
            fontFamily: fontFamily, // Always use the fontFamily parameter if provided
            fontSize: fontSize ?? baseStyle!.fontSize,
            height: height ?? baseStyle!.height,
          )
        : TextStyle(
            fontFamily: fontFamily ?? 'Cairo',
            fontSize: fontSize ?? 14,
            color: const Color(0xFF1A1A1A),
            height: height ?? 1.4,
          );
    


    // Pattern to match any HTML-like tag
    final RegExp tagPattern = RegExp(r'<(/?)([a-zA-Z]+)>(.*?)</\2>');
    int currentIndex = 0;

    for (final Match match in tagPattern.allMatches(text)) {
      final String tagName = match.group(2)!.toLowerCase();
      final String content = match.group(3)!;
      final bool isClosing = match.group(1) == '/';

      // Add text before the tag
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseTextStyle,
        ));
      }

      // Add styled text based on tag
      if (tagStyles.containsKey(tagName) && !isClosing) {
        spans.add(TextSpan(
          text: content,
          style: tagStyles[tagName],
        ));
      } else {
        // If tag not supported, just add the content with base style
        spans.add(TextSpan(
          text: content,
          style: baseTextStyle,
        ));
      }

      currentIndex = match.end;
    }

    // Add remaining text after the last tag
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseTextStyle,
      ));
    }

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(children: spans),
    );
  }
} 