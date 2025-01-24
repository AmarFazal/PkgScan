import 'package:flutter/material.dart';

class ScrollUtils {
  static void scrollToTop(ScrollController controller, VoidCallback onVisible) {
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    onVisible();
  }
}
