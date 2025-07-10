import 'package:flutter/material.dart';

Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  String okButtonText = 'موافق',
  String? cancelButtonText, // If null, only OK button is shown
  VoidCallback? onOkPressed,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        titlePadding: const EdgeInsets.only(top: 30),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        actions: <Widget>[
          SizedBox(
            width: 120,
            height: 45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFbfa98d),
                    Color(0xFFa47764),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  okButtonText,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onOkPressed?.call();
                },
              ),
            ),
          ),
          if (cancelButtonText != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2e3e7),
                  foregroundColor: Colors.black54,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  cancelButtonText,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ]
        ],
      ),
    ),
  );
} 