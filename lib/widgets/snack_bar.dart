import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message) {
  // context'in geçerli olduğundan emin olalım
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
