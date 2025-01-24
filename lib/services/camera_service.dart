import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _cameraController;

  // Kamerayı başlatma fonksiyonu
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first, // Arkadaki kamerayı seçiyoruz
      ResolutionPreset.medium,
    );
    await _cameraController?.initialize();
  }

  CameraController? get cameraController => _cameraController;

  // Fotoğraf çekme fonksiyonu
  Future<String?> capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final XFile photo = await _cameraController!.takePicture();
      return photo.path; // Çekilen fotoğrafın yolu
    }
    return null;
  }

  // Kamerayı durdurma fonksiyonu
  void disposeCamera() {
    _cameraController?.dispose();
  }
}
