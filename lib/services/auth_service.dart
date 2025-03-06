import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/config.dart';

class AuthService {
  Future<String> signup(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.authUrl}/register'),
      headers: {
        'Content-Type': 'application/json', // Content-Type eklendi
      },
      body: jsonEncode({
        'username': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      try {
        return data['message'] ?? 'Signup successful!';
      } catch (e) {
        return response.body;
      }
    } else {
      throw Exception(data['message']);
    }
  }

  Future<String> login(String email, String password) async {
    print('${AppConfig.authUrl}/login');
    final response = await http.post(
      Uri.parse('${AppConfig.authUrl}/login'),
      headers: {
        'Content-Type': 'application/json', // Content-Type eklendi
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      try {
        // Login başarılıysa SharedPreferences kullanarak bilgileri kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // Giriş durumu
        await prefs.setString('userEmail', email); // Email adresi
        await prefs.setString('name', data['username']); // Kullanıcı Adı
        await prefs.setString(
            'accessToken', data['access_token']); // Erişim Belirteci
        await prefs.setString(
            'refreshToken', data['refresh_token']); // Yenileme Belirteci

        return data['message'] ?? 'Login successful!';
      } catch (e) {
        return response.body;
      }
    } else {
      throw Exception('${data['message']}');
    }
  }

  Future<void> continueAsGuest() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true); // Giriş durumu
    await prefs.setBool('isGuestMode', true); // Giriş durumu
    await prefs.setString('userEmail', "guest@gmail.com"); // Email adresi
    await prefs.setString('name', "Guest Mode"); // Kullanıcı Adı

  }


  Future<void> logout(BuildContext context) async {
    final String? accessToken = await getValidAccessToken();

    if (accessToken == null) {
      showSnackBar(context: context, message: 'Access token not found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse("${AppConfig.authUrl}/logout"), // API URL'ni buraya ekle
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userEmail');
      await prefs.remove('name');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signUpWithScreen',
            (Route<dynamic> route) => false,
      );
    } else {
      showSnackBar(context: context, message: response.body);
    }
  }


  Future<void> forgotPassword(String email, BuildContext context) async {
    final response = await http.post(
      Uri.parse('${AppConfig.authUrl}/forgot-password'),
      headers: {
        'Content-Type': 'application/json', // Content-Type eklendi
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link.')),
      );
    }
  }

  Future<String> deleteAccount(String email, String password, BuildContext context) async {
    // Geçerli token alınıyor veya yenileniyor
    final String? accessToken = await getValidAccessToken();

    if (accessToken == null) {
      throw Exception('Access token not found. Please log in again.');
    }

    // API isteği yapılıyor
    final response = await http.post(
      Uri.parse('${AppConfig.authUrl}/delete-account'),
      headers: {
        'Content-Type': 'application/json', // JSON formatında veri gönderiliyor
        'Authorization': 'Bearer $accessToken', // Token ekleniyor
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = response.body;

    if (response.statusCode == 200) {
      // Başarılı işlem sonrası kullanıcıyı giriş sayfasına yönlendir
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signUpWithScreen',
        (Route<dynamic> route) => false,
      );

      try {
        // SharedPreferences'tan kullanıcı bilgileri temizleniyor
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');
        await prefs.remove('userEmail');
        await prefs.remove('name');
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        return data;
      } catch (e) {
        return data;
      }
    } else {
      throw Exception(data); // Hata mesajı
    }
  }

  Future<void> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      throw Exception('Refresh token not found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.authUrl}/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken', // Token ekleniyor
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String newAccessToken = data['access_token'];

      // 15 dakikalık süreyi sabit olarak belirliyoruz
      const int expiresIn = 13 * 60; // 15 dakika = 900 saniye

      // Yeni token ve süresini kaydediyoruz
      await prefs.setString('accessToken', newAccessToken);
      await prefs.setString(
        'lastRefresh',
        DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
      );
    } else {
      throw Exception(
          'Failed to refresh token. Status: ${response.statusCode}');
    }
  }

  void startTokenRefreshScheduler() {
    print("Starting token refresh scheduler...");

    // 15 dakika (900 saniye) aralıkla token'ı yeniliyoruz
    Timer.periodic(Duration(minutes: 13), (timer) async {
      print("Timer triggered for refreshing access token.");

      try {
        await refreshAccessToken(); // Token yenileme işlemi
        print("Access token refreshed successfully.");
      } catch (e) {
        print("Failed to refresh token: $e"); // Hata mesajını logla
        timer.cancel(); // Hata durumunda zamanlayıcıyı durdur
      }
    });

    print("Token refresh scheduler started successfully.");
  }

  Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('accessToken');
    final String? lastRefreshStr = prefs.getString('lastRefresh');

    DateTime? lastRefresh;

    if (lastRefreshStr != null) {
      lastRefresh = DateTime.tryParse(lastRefreshStr);
    }

    if (lastRefresh != null && DateTime.now().isAfter(lastRefresh)) {
      // Eğer son yenileme zamanı dolmuşsa, yeni token almak için refresh yapılır
      await refreshAccessToken();
      return prefs.getString('accessToken');
    }

    return accessToken; // Eğer geçerli bir token varsa, mevcut token döndürülür
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ??
        false; // Varsayılan olarak false döner
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail'); // Email varsa döner, yoksa null döner
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name'); // Email varsa döner, yoksa null döner
  }

  Future<String?> getUserAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<String?> getUserRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }
}
