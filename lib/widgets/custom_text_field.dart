import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? errorText;
  final bool hasError;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets padding;
  final bool obscureText;

  const CustomTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.value,
    this.onChanged,
    this.keyboardType,
    this.enabled = true,
    this.errorText,
    this.hasError = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null) ...[
              Text(
                labelText!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
            ],
            TextFormField(
              initialValue: value,
              onChanged: onChanged,
              keyboardType: keyboardType,
              enabled: enabled,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError 
                        ? Colors.red.withValues(alpha: 0.6)
                        : const Color.fromARGB(255, 218, 218, 218),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError 
                        ? Colors.red.withValues(alpha: 0.6)
                        : const Color.fromARGB(255, 218, 218, 218),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError 
                        ? Colors.red.withValues(alpha: 0.6)
                        : const Color(0xFFA47764), 
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6), width: 1),
                ),
                errorText: hasError ? null : errorText,
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 