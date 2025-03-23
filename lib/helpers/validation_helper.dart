import 'package:flutter/material.dart';

import '../services/record_service.dart';

class ValidationHelper {
  final RecordService _recordService;

  // Dependency Injection via constructor
  ValidationHelper(this._recordService);

  void checkImageForChanges({
    required String key,
    required Map<String, dynamic> newValue,
    required Map<String, String> imageValues,
    required Map<String, dynamic> oldImageValues,
    required String entitiesId,
    String? recordId,
    required BuildContext context,
    required VoidCallback updateState,
  }) {
    if (oldImageValues[key] != null && oldImageValues[key] != newValue) {
      _recordService.updateRecord(
        context,
        entitiesId,
        recordId!,
        newValue,
        oldImageValues,
      );

      updateState();
      oldImageValues[key] = newValue;
      imageValues[key] = newValue[key];
    }
  }

  void checkBooleanForChanges({
    required String key,
    required Map<String, dynamic> newValue,
    required Map<String, dynamic> oldBooleanValues,
    required String entitiesId,
    String? recordId,
    required BuildContext context,
    required VoidCallback updateState,
  }) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      _recordService.updateRecord(
        context,
        entitiesId,
        recordId!,
        newValue,
        oldBooleanValues,
      );
      updateState();
      oldBooleanValues[key] = newValue;
    }
  }
}
