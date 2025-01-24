import 'package:flutter/material.dart';


// SnackBar mesajını göstermek için yardımcı fonksiyon
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(message),
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}