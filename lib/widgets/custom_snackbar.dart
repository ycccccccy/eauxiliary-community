// lib/widgets/custom_snackbar.dart

import 'package:flutter/material.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    required SnackbarType type,
  }) {
// 为了支持深浅色模式，不再使用传入颜色，而是根据 SnackbarType 使用不同的颜色
    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case SnackbarType.warning:
        backgroundColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red;
        iconData = Icons.error;
        break;
      case SnackbarType.success:
        backgroundColor = Colors.green;
        iconData = Icons.check_circle;
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          Icon(iconData, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(
        // 设置边距
        bottom: 100,
        left: 20,
        right: 20,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

enum SnackbarType {
  warning,
  error,
  success,
}
