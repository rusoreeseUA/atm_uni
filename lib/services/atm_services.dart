import 'package:flutter/material.dart';

class ATMService {
  /// Показ кастомного SnackBar
  static void showCustomSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// SnackBar успішного виконання
  static void showSuccess(BuildContext context, String message) {
    showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green.shade600,
    );
  }

  /// SnackBar у разі помилки
  static void showError(BuildContext context, String message) {
    showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red.shade600,
    );
  }

  /// SnackBar інформаційного повідомлення
  static void showInfo(BuildContext context, String message) {
    showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.grey.shade700,
    );
  }


  
}