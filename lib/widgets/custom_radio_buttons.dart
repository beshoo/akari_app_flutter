import 'package:flutter/material.dart';

class RadioOption {
  final String id;
  final String label;
  final String value;
  final double size;
  final Color color;

  const RadioOption({
    required this.id,
    required this.label,
    required this.value,
    this.size = 20.0,
    this.color = const Color(0xFFA47764),
  });
}

class CustomRadioButtons extends StatelessWidget {
  final List<RadioOption> radioButtons;
  final String? selectedId;
  final ValueChanged<String>? onChanged;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;

  const CustomRadioButtons({
    super.key,
    required this.radioButtons,
    this.selectedId,
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          children: radioButtons.map((option) {
            final isSelected = selectedId == option.id;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged?.call(option.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: option.size,
                        height: option.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? option.color : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: option.size * 0.5,
                                  height: option.size * 0.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: option.color,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? option.color : Colors.grey[700],
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
} 