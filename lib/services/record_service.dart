import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/config.dart';
import '../widgets/snack_bar.dart';
import 'auth_service.dart';

class RecordService {
  // Add Record
  Future<String?> addRecord(BuildContext context, String entityId,
      bool isScrape, String scrapeBy, String scrapeValue) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.recordsUrl}/add-record'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: json.encode({
          "entity_id": entityId,
          "is_scrape": isScrape,
          "scrape_by": scrapeBy,
          "scrape_value": scrapeValue
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['message'] ?? 'Record added successfully!';
      } else {
        //showSnackBar(context, '${data['message']}');
        return '${data['message']}';
      }
    } catch (e) {
      //showSnackBar(context, 'Error occurred: $e');
      return 'Error occurred: $e';
    }
  }

  // Retrieve Records
  Future retrieveRecords(
      BuildContext context, String entityId, String search) async {
    try {
      final String? accessToken = await AuthService().getValidAccessToken();
      if (accessToken == null) {
        showSnackBar(context, 'Access token not found. Please log in again.');
        return;
      }

      final response = await http.get(
        search.isNotEmpty
            ? Uri.parse('${AppConfig.recordsUrl}/search/$entityId?q=$search')
            : Uri.parse('${AppConfig.recordsUrl}/get/$entityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Eğer cevap boşsa, 'No records found' mesajını göster
      if (response.body.isEmpty) {
        showSnackBar(context, 'No records found.');
        return [];
      }

      final data = jsonDecode(response.body); // Cevap boş değilse devam et
      if (response.statusCode == 200) {
        final dynamic jsonData = data;

        // Gelen veri bir liste mi yoksa bir obje mi kontrol ediliyor
        if (jsonData is List) {
          return jsonData
              .cast<Map<String, dynamic>>(); // Listeyse, doğru şekilde döndür
        } else if (jsonData is Map<String, dynamic>) {
          return [jsonData]; // Obje ise, listeye sararak döndür
        } else {
          showSnackBar(context, 'Invalid data format received.');
        }
      } else {
        showSnackBar(context,
            'Failed to load records. Status code: ${response.statusCode}');
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
      print(e);
    }
  }

  // Archive Records
  Future<void> archiveRecord(BuildContext context, String recordId,
      String entityId, Function onSuccess) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return;
    }

    try {
      // PUT isteği yapılıyor
      final response = await http.patch(
        Uri.parse('${AppConfig.recordsUrl}/archive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          "entity_id": entityId,
          "records_ids": [recordId],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Başarı mesajını göster
        final successMessage = data['message'] ?? 'Archive successful!';
        showSnackBar(context, successMessage);

        // Callback fonksiyonu çağır
        onSuccess(); // Callback fonksiyonu çağrılır
      } else {
        // Hata mesajını göster
        final errorMessage = data['message'] ?? 'An error occurred.';
        showSnackBar(context, errorMessage);
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
  }

  // Update Records
  Future<List<Map<String, dynamic>>> updateRecord(
      BuildContext context,
      String entityId,
      String recordId,
      Map<String, dynamic> updatingData,
      Map currentData) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return [];
    }

    // Yalnızca değişen verileri bul
    Map<String, dynamic> changedData = {};

    updatingData.forEach((key, value) {
      if (currentData[key] != value) {
        changedData[key] = value;
      }
    });

    if (changedData.isEmpty) {
      showSnackBar(context, 'No changes detected.');
      return [];
    }

    try {
      // PUT isteği yapılıyor
      final response = await http.put(
        Uri.parse('${AppConfig.recordsUrl}/update/$recordId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          "entity_id": entityId,
          "data": changedData,
        }),
      );
      print("Service'te olan ID: $updatingData");

      // Yanıt formatını kontrol etmeden önce durumu kontrol et
      if (response.statusCode != 200) {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'An error occurred.';
        showSnackBar(context, errorMessage);
        return [];
      }

      // Yanıtı çözümleyin
      final data = jsonDecode(response.body);

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        return [data.cast<String, dynamic>()];
      } else {
        showSnackBar(context, 'Unexpected response format.');
        return [];
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
      return [];
    }
  }
}
