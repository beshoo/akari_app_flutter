import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T) itemValue;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final String? labelText;
  final String? emptyMessage;
  final bool isEnabled;
  final bool isLoading;
  final String? errorText;
  final bool hasError;

  const CustomDropdown({
    super.key,
    this.value,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    this.onChanged,
    this.hintText,
    this.labelText,
    this.emptyMessage,
    this.isEnabled = true,
    this.isLoading = false,
    this.errorText,
    this.hasError = false,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final GlobalKey _dropdownKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
          GestureDetector(
            key: _dropdownKey,
            onTap: widget.isEnabled && !widget.isLoading && widget.items.isNotEmpty
                ? _toggleDropdown
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(
                  color: widget.hasError
                      ? Colors.red.withValues(alpha: 0.6)
                      : const Color.fromARGB(255, 218, 218, 218),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 1,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayText(),
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null
                            ? Colors.black87
                            : const Color(0xFF8C7A6A),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  if (widget.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF8C7A6A),
                        ),
                      ),
                    ),
                  if (widget.isLoading) const SizedBox(width: 8),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: widget.isEnabled ? const Color(0xFF8C7A6A) : const Color(0xFFB8B8B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (widget.errorText != null && !widget.hasError) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (widget.value != null) {
      return widget.itemLabel(widget.value as T);
    }
    
    if (widget.items.isEmpty && widget.emptyMessage != null) {
      return widget.emptyMessage!;
    }
    
    return widget.hintText ?? 'اختر...';
  }

  bool _shouldShowScrollbar() {
    if (widget.items.isEmpty) return false;
    
    // Each item has approximately 44px height (14px top + 14px bottom padding + ~16px text)
    const double itemHeight = 44.0;
    const double maxHeight = 200.0;
    
    double totalContentHeight = widget.items.length * itemHeight;
    return totalContentHeight > maxHeight;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry);
    setState(() {
      _isOpen = true;
    });
    _animationController.forward();
  }

  void _closeDropdown() async {
    await _animationController.reverse();
    if (mounted) {
      _overlayEntry.remove();
      setState(() {
        _isOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.black.withValues(alpha: 0.4 * _opacityAnimation.value), // Animated backdrop
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from bubbling up to parent
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
                        constraints: const BoxConstraints(
                          maxHeight: 400,
                          maxWidth: 400,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4C4B0),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.items.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 48,
                                        color: const Color(0xFF8C7A6A),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.emptyMessage ?? 'لا توجد عناصر للاختيار',
                                        style: const TextStyle(
                                          color: Color(0xFF8C7A6A),
                                          fontFamily: 'Cairo',
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: _shouldShowScrollbar(),
                                  radius: const Radius.circular(8),
                                  thickness: 4,
                                  child: MediaQuery.removePadding(
                                    context: context,
                                    removeTop: true,
                                    removeBottom: true,
                                    child: ListView.builder(
                                      primary: false,
                                      controller: _scrollController,
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: widget.items.length,
                                      itemBuilder: (context, index) {
                                        final item = widget.items[index];
                                        final isSelected = widget.value != null &&
                                            widget.itemValue(widget.value as T) == widget.itemValue(item);

                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              widget.onChanged?.call(item);
                                              _closeDropdown();
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFFA47764).withValues(alpha: 0.15)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: const Color(0xFFA47764).withValues(alpha: 0.3),
                                                        width: 1,
                                                      )
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      widget.itemLabel(item),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: isSelected
                                                            ? const Color(0xFFA47764)
                                                            : Colors.black87,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Color(0xFFA47764),
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isOpen) {
      _overlayEntry.remove();
    }
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 