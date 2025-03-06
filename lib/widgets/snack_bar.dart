import 'package:flutter/material.dart';

void showSnackBar({required BuildContext context, required String message, int duration = 2}) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
      ),
    );
  }
}
