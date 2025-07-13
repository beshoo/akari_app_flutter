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

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final GlobalKey _dropdownKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

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
  }

  void _closeDropdown() {
    _overlayEntry.remove();
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _closeDropdown,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Actual dropdown positioned where it should be
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 6,
                width: size.width,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from bubbling up to parent
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4C4B0),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  widget.emptyMessage ?? 'لا توجد عناصر للاختيار',
                                  style: TextStyle(
                                    color: const Color(0xFF8C7A6A),
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: _shouldShowScrollbar(),
                                radius: const Radius.circular(8),
                                thickness: 3,
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
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFA47764).withValues(alpha: 0.08)
                                                  : Colors.transparent,
                                            ),
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
            ],
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
    super.dispose();
  }
} 