import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_pkgscan/constants/app_colors.dart';
import 'package:flutter_pkgscan/constants/config.dart';
import 'package:flutter_pkgscan/services/auth_service.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  final String entityId;

  const CameraScreen({Key? key, required this.entityId}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Kamerayı başlatıyoruz
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first, // Arkadaki kamera
      ResolutionPreset.high, // Çözünürlük ayarı
    );
    await _cameraController?.initialize();
    setState(() {});
  }

  // Kamera kapatma
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // Fotoğraf çekme ve POST isteği gönderme
  Future<void> _captureAndUploadPhoto() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Fotoğrafı çekiyoruz
      final XFile photo = await _cameraController!.takePicture();

      // Yükleniyor göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Image Uploading..."),
              ],
            ),
          );
        },
      );

      // Çekilen fotoğrafı POST ile gönderiyoruz
      final url = Uri.parse("https://5f46-149-54-25-157.ngrok-free.app/upload-img-cloud");
      final request = http.MultipartRequest('POST', url);

      final String? checkedAccessToken = await AuthService().getValidAccessToken();

      if (checkedAccessToken == null) {
        showSnackBar(context, 'Access token not found. Please log in again.');
        return null;
      }

      // Fotoğraf dosyasını ekliyoruz
      request.files.add(
        await http.MultipartFile.fromPath('file', photo.path),
      );

      // Authorization header ekliyoruz
      final accessToken = checkedAccessToken; // Burada token'ınızı dinamik olarak alın
      request.headers['Authorization'] = 'Bearer $accessToken';

      // İstek gönderiliyor
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // JSON yanıtını çözüyoruz
      final Map<String, dynamic> jsonResponse = json.decode(responseData);

      if (jsonResponse['url'] != null) {
        final imageUrl = jsonResponse['url'];

        // RecordService'e veriyi gönderiyoruz
        final String? data = await RecordService().addRecord(
          context,
          widget.entityId,
          true,
          "image-search",
          imageUrl,
        );

        // Snackbar ile mesaj gösteriyoruz
        if (data != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data)));
        }

        // Dialog'u kapatıyoruz ve sonucu geri döndürüyoruz
        Navigator.pop(context, imageUrl);
      } else {
        Navigator.pop(context);
        throw Exception("Photo upload failed!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });

      Navigator.pop(context); // Yükleniyor göstergesini kapatıyoruz
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(

      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(

        height: MediaQuery.of(context).size.height * 0.9,
        child: Stack(
          children: [
            Center(child: CameraPreview(_cameraController!)), // Kamera önizleme
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap:  _isProcessing ? null : _captureAndUploadPhoto,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(100),),
                    child: Icon(Icons.camera_alt,color: AppColors.primaryColor,size: 35,),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
