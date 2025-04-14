import 'package:flutter/material.dart';
import '../services/entities_service.dart';
import '../services/record_service.dart';
import '../utils/records/record_helpers.dart';

class RecordDataService {
  final RecordService _recordService;
  final EntitiesService _entitiesService;

  RecordDataService(this._recordService, this._entitiesService);

  Future<Map<String, dynamic>?> fetchRecordData(
    BuildContext context,
    String entitiesId,
    int? index,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> oldValues,
    Map<String, bool> dynamicBooleans,
    Map<String, dynamic> oldBooleanValues,
    Map<String, String> imageValues,
    List<Map<String, String>> combinedList,
  ) async {
    final data = await _recordService.retrieveRecords(context, entitiesId, '');
    if (data != null && data.isNotEmpty) {
      final record = data[0]['records'][index];

      // Initialize controllers, boolean values, and image values dynamically
      RecordHelpers.initializeControllers(
          controllers, oldValues, record['data']);
      RecordHelpers.initializeDynamicBooleans(
          dynamicBooleans, oldBooleanValues, record['data']);
      RecordHelpers.initializeImageValues(imageValues, record['data']);

      // Organize and sort keys for dynamic lists
      prepareCombinedList(record['data'], combinedList);

      return record;
    }
    return null;
  }

  void saveRecordData({
    required BuildContext context,
    required Map controllers,
    required Map imageValues,
    required Map oldValues,
    required String entitiesId,
    required String? recordId,
    required bool isNew,
    required bool isRecordScreen,
    String? recordRequestId,
  }) {
    Map<String, dynamic> updatedData = controllers.map((key, controller) {
      return MapEntry(key, controller.text);
    });
    updatedData.forEach((key, value) {
      if (oldValues.containsKey(key) && oldValues[key] != value) {
        print('Changed field: $key | OLD: ${oldValues[key]} -> NEW: $value');
      }
    });
    Map<String, dynamic> changedData = {};
    bool isChanged = false;

    updatedData.forEach((key, value) {
      // Eğer eski verilerde bu anahtar varsa
      if (oldValues.containsKey(key)) {
        // Eski değer ile yeni değeri karşılaştır
        if (oldValues[key] != value || oldValues[key] == null || oldValues[key] == '') {
          // Eski değer boşsa veya farklıysa, yeni değeri kaydet
          changedData[key] = value;
          isChanged = true;
        }
      } else {
        // Eğer eski değeri hiç yoksa (yani boş bir alan yeni eklenmişse)
        if (value != null && value != '') {
          // Eğer yeni değer boş değilse, o zaman kaydet
          changedData[key] = value;
          isChanged = true;
        }
      }
    });

    if (isChanged) {
      changedData["Scrape Status"] = "Customer Updated";
    }
    imageValues.forEach((key, value) {
      if (value.isNotEmpty) {
        updatedData[key] = value;
        if (isRecordScreen) {
          controllers[key]?.text = value;
        }
      }
    });
    controllers.forEach((key, controller) {
      updatedData[key] = controller.text;
    });

    isNew == false
        ? _recordService.updateRecord(
            context, entitiesId, recordId, changedData, oldValues)
        : RecordService().addRecord(
            context,
            entitiesId,
            false,
            "",
            "",
            true,
      changedData,recordRequestId!,
          );
    if (isRecordScreen) Navigator.pop(context, true);
  }

  void prepareCombinedList(
      Map<String, dynamic> data, List<Map<String, String>> combinedList) {
    List<String> imageKeys = getSortedKeysStartingWith(data, "Image ");
    List<String> titleKeys = getSortedKeysStartingWith(data, "Title ");
    List<String> msrpKeys = getSortedKeysStartingWith(data, "MSRP ");

    combinedList.clear();
    for (int i = 0; i < imageKeys.length; i++) {
      String imageUrl = data[imageKeys[i]]?.toString() ?? '';
      String title =
          i < titleKeys.length ? data[titleKeys[i]]?.toString() ?? '' : '';
      String msrp =
          i < msrpKeys.length ? data[msrpKeys[i]]?.toString() ?? '' : '';

      if (imageUrl.isNotEmpty || title.isNotEmpty || msrp.isNotEmpty) {
        combinedList.add({'image': imageUrl, 'title': title, 'msrp': msrp});
      }
    }
  }

  Future<Map<String, dynamic>?> retrieveEntity(
    BuildContext context,
    String entitiesId,
    Map<String, bool> dynamicBooleans,
    Map<String, String> imageValues,
  ) async {
    final entity = await _entitiesService.retrieveEntities(context, entitiesId);
    if (entity != null) {
      entity['groupedAttributes']?.forEach((key, attributes) {
        attributes.forEach((attribute) {
          if (attribute['type'] == 'boolean' && attribute['key'] != null) {
            dynamicBooleans[attribute['key']] = attribute['value'] ?? false;
          }
          if (attribute['type'] == 'image' && attribute['key'] != null) {
            imageValues[attribute['key']] = attribute['value'] ?? '';
          }
        });
      });
    }
    return entity;
  }

  List<String> getSortedKeysStartingWith(
      Map<String, dynamic> data, String prefix) {
    return data.keys.where((key) => key.startsWith(prefix)).toList()..sort();
  }
}
