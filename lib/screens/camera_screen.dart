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

import '../services/cloud_service.dart';

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

  Future<void> _captureAndUploadPhoto() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();

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

      final String? imageUrl =
      await CloudService().uploadPhotoToCloud(context, photo.path);

      if (imageUrl != null) {
        // RecordService'e gönderme işlemini burada kullanmaya devam edebilirsiniz
        final String? data = await RecordService().addRecord(
          context,
          widget.entityId,
          true,
          "image-search",
          imageUrl,
        );

        if (data != null) {
          showSnackBar(context, data);
        }

        Navigator.pop(context, imageUrl); // İşlem tamamlandığında geri dön
      } else {
        throw Exception("Failed to get the image URL.");
      }
    } catch (e) {
      showSnackBar(context, "An error occurred: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });

      Navigator.pop(context);
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
