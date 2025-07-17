import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
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
  final bool showClearButton;

  const CustomTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.value,
    this.onChanged,
    this.onClear,
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
    this.showClearButton = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  bool _showClearIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _showClearIcon = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_showClearIcon != hasText) {
      // Defer setState to avoid calling it during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showClearIcon = hasText;
          });
        }
      });
    }
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _clearText() {
    _controller.clear();
    if (widget.onClear != null) {
      widget.onClear!();
    }
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;
    
    // Add clear button as suffix icon (right side in RTL) if enabled and text is present
    if (widget.showClearButton && _showClearIcon && widget.enabled) {
      effectiveSuffixIcon = GestureDetector(
        onTap: _clearText,
        child: Container(
          margin: const EdgeInsets.only(left: 8, right: 8),
          child: Icon(
            Icons.cancel_rounded,
            color: Colors.grey[600],
            size: 20,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null) ...[
              Text(
                widget.labelText!,
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
              controller: _controller,
              keyboardType: widget.keyboardType,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              inputFormatters: widget.inputFormatters,
              obscureText: widget.obscureText,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
                color: Colors.black87,
              ),
                              decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: effectiveSuffixIcon,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.hasError 
                        ? Colors.red.withValues(alpha: 0.6)
                        : const Color.fromARGB(255, 218, 218, 218),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.hasError 
                        ? Colors.red.withValues(alpha: 0.6)
                        : const Color.fromARGB(255, 218, 218, 218),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.hasError 
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
                errorText: widget.hasError ? null : widget.errorText,
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