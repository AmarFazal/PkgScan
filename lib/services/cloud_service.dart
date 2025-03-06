import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pkgscan/constants/config.dart';
import 'package:flutter_pkgscan/services/auth_service.dart';

class CloudService {
  Future<String?> uploadPhotoToCloud(BuildContext context, String photoPath) async {
    try {
      final url = Uri.parse("${AppConfig.url}/upload-img-cloud");
      final request = http.MultipartRequest('POST', url);

      // Token alınıyor
      final String? checkedAccessToken =
      await AuthService().getValidAccessToken();
      if (checkedAccessToken == null) {
        throw Exception("Access token not found. Please log in again.");
      }

      // Fotoğraf dosyasını ekle
      request.files.add(
        await http.MultipartFile.fromPath('file', photoPath),
      );

      // Authorization header ekleniyor
      request.headers['Authorization'] = 'Bearer $checkedAccessToken';

      // İstek gönderiliyor
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // JSON yanıtı çözüyoruz
      final Map<String, dynamic> jsonResponse = json.decode(responseData);

      if (jsonResponse['url'] != null) {
        return jsonResponse['url']; // Fotoğraf URL'sini döndür
      } else {
        showSnackBar(context: context, message: jsonResponse['message']);
        throw Exception("Photo upload failed!");
      }
    } catch (e) {
      showSnackBar(context: context, message: "An error occurred during photo upload: $e");
    }
    return null;
  }
}
