import 'package:flutter/material.dart';

class AttributeStateNotifier extends ChangeNotifier {
  Map<String, TextEditingController> controllers = {};
  Map<String, bool> booleans = {};
  Map<String, String> images = {};

  void updateBoolean(String key, bool value) {
    booleans[key] = value;
    notifyListeners();
  }

  void updateImage(String key, String value) {
    images[key] = value;
    notifyListeners();
  }

  void initializeControllers(Map<String, dynamic> attributes) {
    attributes.forEach((key, value) {
      if (value['type'] == 'string' || value['type'] == 'integer') {
        controllers[key] = TextEditingController(text: value['value']?.toString());
      }
    });
  }
}
