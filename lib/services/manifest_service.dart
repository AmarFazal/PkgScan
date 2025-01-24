import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/constants/config.dart';
import 'package:flutter_pkgscan/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/snack_bar.dart';

class ManifestService {
  // Add Manifest
  Future<void> addManifest(BuildContext context, String name, String description, IconData icon) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return;
    }

    try {
      // POST isteği yapılıyor
      final response = await http.post(
        Uri.parse('${AppConfig.manifestsUrl}/add-manifest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: json.encode({
          "name": name,
          "description": description,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Başarılı mesajı göster
        showSnackBar(
            context, data['message'] ?? 'Manifest added successfully!');
      } else {
        // Hata mesajını göster
        showSnackBar(context, data['message'] ?? 'An error occurred.');
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
  }

  // Retrieve Manifest
  Future retrieveManifests(BuildContext context) async {
    try {
      final String? accessToken = await AuthService().getValidAccessToken();
      if (accessToken == null) {
        showSnackBar(context, 'Access token not found. Please log in again.');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.manifestsUrl}/retrieve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();  // Veriyi döndür
      } else {
        showSnackBar(context, 'Failed to fetch manifests.');
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
  }

  // Edit Manifest
  Future<List<Map<String, dynamic>>> editManifest(BuildContext context, String manifestId, String name, String description) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return [];
    }

    try {
      // PUT isteği yapılıyor
      final response = await http.put(
        Uri.parse('${AppConfig.manifestsUrl}/edit-manifest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          "manifest_id": manifestId,
          "name": name,
          "description": description
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

  // Archive Manifest
  Future<void> archiveManifest(BuildContext context, String manifestId, Function onSuccess) async {
    final String? accessToken = await AuthService().getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context, 'Access token not found. Please log in again.');
      return;
    }

    try {
      // PUT isteği yapılıyor
      final response = await http.patch(
        Uri.parse('${AppConfig.manifestsUrl}/archive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          "manifests_ids": [manifestId],
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Başarı mesajını göster
        final successMessage = data['message'] ?? 'Archive successful!';
        showSnackBar(context, successMessage);

        // Callback fonksiyonu çağır
        onSuccess();  // Callback fonksiyonu çağrılır
      } else {
        // Hata mesajını göster
        final errorMessage = data['message'] ?? 'An error occurred.';
        showSnackBar(context, errorMessage);
      }
    } catch (e) {
      showSnackBar(context, 'Something went wrong: $e');
    }
  }



}
