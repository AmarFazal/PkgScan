import 'package:flutter/material.dart';

class DynamicAttributeState {
  Map<String, TextEditingController> controllers = {};
  Map<String, bool> booleanValues = {};
  Map<String, dynamic> imageValues = {};

  void initializeAttributes(List<dynamic> attributes) {
    for (var attribute in attributes) {
      if (attribute['type'] == 'boolean') {
        booleanValues[attribute['key']] = attribute['value'] ?? false;
      } else if (attribute['type'] == 'image') {
        imageValues[attribute['key']] = attribute['value'] ?? '';
      } else if (attribute['type'] == 'string' || attribute['type'] == 'integer') {
        controllers[attribute['key']] = TextEditingController(text: attribute['value']?.toString());
      }
    }
  }
}