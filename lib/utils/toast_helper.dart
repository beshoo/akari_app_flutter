import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  static void showToast(
    BuildContext context,
    String message, {
    required bool isError,
    Duration duration = const Duration(seconds: 4),
  }) {
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: isError ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.minimal,
      title: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      alignment: Alignment.topCenter,
      direction: TextDirection.rtl,
      autoCloseDuration: duration,
      showProgressBar: true,
      closeButton: const ToastCloseButton(
        showType: CloseButtonShowType.onHover,
      ),
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      animationDuration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 16,
          offset: Offset(0, 8),
          spreadRadius: 0,
        )
      ],
    );
  }
} 