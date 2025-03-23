import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollListenerHelper {
  final ScrollController scrollController;
  final Function(bool) onVisibilityChange;

  ScrollListenerHelper({
    required this.scrollController,
    required this.onVisibilityChange,
  });

  void addListener() {
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        onVisibilityChange(false);
      } else if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
        onVisibilityChange(true);
      }
    });
  }

  void dispose() {
    scrollController.dispose();
  }
}
