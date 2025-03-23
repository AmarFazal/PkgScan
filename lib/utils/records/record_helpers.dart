// lib/utils/record_helpers.dart
import 'package:flutter/material.dart';

class RecordHelpers {
  // Initialize the text controllers for each field dynamically
  static void initializeControllers(
      Map<String, TextEditingController> controllers,
      Map<String, dynamic> oldValues,
      Map<String, dynamic> data,
      ) {
    data.forEach((key, value) {
      if (!controllers.containsKey(key)) {
        controllers[key] = TextEditingController(text: value?.toString());
        oldValues[key] = value?.toString() ?? '';
      }
    });
  }

  // Initialize the dynamic boolean values based on the data
  static void initializeDynamicBooleans(
      Map<String, bool> dynamicBooleans,
      Map<String, dynamic> oldBooleanValues,
      Map<String, dynamic> data,
      ) {
    data.forEach((key, value) {
      if (!dynamicBooleans.containsKey(key)) {
        dynamicBooleans[key] = _parseBoolean(value);
        oldBooleanValues[key] = value?.toString() ?? '';
      }
    });
  }

  // Initialize image values based on the data
  static void initializeImageValues(
      Map<String, String> imageValues,
      Map<String, dynamic> data,
      ) {
    data.forEach((key, value) {
      if (!imageValues.containsKey(key)) {
        imageValues[key] = value?.toString() ?? '';
      }
    });
  }

  // Parse the value to a boolean (handles both string and boolean types)
  static bool _parseBoolean(dynamic value) {
    if (value is String) {
      return value.toLowerCase() == 'true';
    } else if (value is bool) {
      return value;
    }
    return false;
  }
}