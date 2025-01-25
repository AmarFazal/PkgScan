import 'dart:convert';
import 'dart:developer';

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

  Future<Map<String, dynamic>?> updateEntities(
      BuildContext context, String? entityId, Map<String, dynamic> body) async {
    try {
      final String? accessToken = await AuthService().getValidAccessToken();
      if (accessToken == null) {
        showSnackBar(context, 'Access token not found. Please log in again.');
        return null;
      }

      final response = await http.put(
        Uri.parse('${AppConfig.entitiesUrl}/update-entity/$entityId'),
        body: jsonEncode({
          "manifest_settings": body
        }),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      // log("update entities ${response.body}");
      if (response.statusCode == 200) {
        // JSON'u çöz ve entity kısmını çıkar
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final entity = data['entity'] as Map<String, dynamic>;
        final successMessage = data['message'] ?? 'Entity updated successfully.';
        showSnackBar(context, successMessage);

        return entity; // Veriyi döndür
      } else {
        showSnackBar(context, 'Failed to fetch manifests.');
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
    return null;
  }
}
