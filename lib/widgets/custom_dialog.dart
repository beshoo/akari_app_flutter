import 'package:flutter/material.dart';

Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  String okButtonText = 'موافق',
  String? cancelButtonText, // If null, only OK button is shown
  VoidCallback? onOkPressed,
  bool isWarning = false,
}) async {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation1, animation2) => const SizedBox.shrink(),
    transitionBuilder: (context, animation1, animation2, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation1,
        curve: Curves.easeOutBack,
      ));

      final opacityAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation1,
        curve: Curves.easeOut,
      ));

      return AnimatedBuilder(
        animation: animation1,
        builder: (context, child) => Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.4 * opacityAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Opacity(
                opacity: opacityAnimation.value,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(
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
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                                decoration: TextDecoration.none,
                                backgroundColor: Colors.transparent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Message
                            Text(
                              message,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 19,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF8C7A6A),
                                height: 1.4,
                                decoration: TextDecoration.none,
                                backgroundColor: Colors.transparent,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // OK Button
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isWarning
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFFD32F2F),
                                                Color(0xFFB71C1C),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFFbfa98d),
                                                Color(0xFFa47764),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isWarning ? Colors.red : const Color(0xFFa47764))
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          onOkPressed?.call();
                                        },
                                        child: Center(
                                          child: Text(
                                            okButtonText,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Cancel Button (if provided)
                                if (cancelButtonText != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F5F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE0E0E0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => Navigator.of(context).pop(),
                                          child: Center(
                                            child: Text(
                                              cancelButtonText,
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Color(0xFF8C7A6A),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
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
    },
  );
} 