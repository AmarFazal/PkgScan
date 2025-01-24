import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/config.dart';
import '../widgets/snack_bar.dart';
import 'auth_service.dart';

class EntitiesService {
  Future<Map<String, dynamic>?> retrieveEntities(
      BuildContext context, String? entityId) async {
    try {
      final String? accessToken = await AuthService().getValidAccessToken();
      if (accessToken == null) {
        showSnackBar(context, 'Access token not found. Please log in again.');
        return null;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.entitiesUrl}/get-entity/$entityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        // JSON'u çöz ve entity kısmını çıkar
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        final entity = data['entity'] as Map<String, dynamic>;

        return entity; // Veriyi döndür
      } else {
        showSnackBar(context, 'Failed to fetch manifests.');
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> editEntity(BuildContext context, String entityId, Map<String, dynamic> updatingData,) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return [];
    }

    try {
      // PUT isteği yapılıyor
      final response = await http.put(
        Uri.parse('${AppConfig.entitiesUrl}/update-entity/$entityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          "data": updatingData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Başarı mesajını göster
        final successMessage = data['message'] ?? 'Edit successful!';
        showSnackBar(context, successMessage);

        // Eğer data bir listeyse, listeye dönüştür
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          return [
            data.cast<String, dynamic>()
          ]; // Map<String, dynamic> olarak dönüştür
        } else {
          showSnackBar(context, 'Unexpected response format.');
          return [];
        }
      } else {
        // Hata mesajını göster
        final errorMessage = data['message'] ?? 'An error occurred.';
        showSnackBar(context, errorMessage);
        return [];
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
      return [];
    }
  }
}
