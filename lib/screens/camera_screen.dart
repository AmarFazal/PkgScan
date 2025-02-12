import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_pkgscan/constants/app_colors.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import '../services/cloud_service.dart';

class CameraScreen extends StatefulWidget {
  final String entityId;
  final VoidCallback onRecordAdded; // Callback ekleyin

  const CameraScreen({
    Key? key,
    required this.entityId,
    required this.onRecordAdded, // Callback parametresi
  }) : super(key: key);

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

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );
    await _cameraController?.initialize();
    setState(() {});
  }

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

    final BuildContext currentContext = context;

    try {
      final XFile photo = await _cameraController!.takePicture();

      // Kamera ekranını hemen kapat
      if (mounted) {
        Navigator.pop(currentContext);
      }

      final String? imageUrl =
          await CloudService().uploadPhotoToCloud(currentContext, photo.path);

      if (imageUrl != null) {
        final String? data = await RecordService().addRecord(
          currentContext,
          widget.entityId,
          true,
          "image-search",
          imageUrl,
        );

        if (data != null && mounted) {
          showSnackBar(currentContext, data);
        }

        // Callback'i çağır (addRecord tamamlandığında)
        widget.onRecordAdded();
      } else {
        throw Exception("Failed to get the image URL.");
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(currentContext, "An error occurred: $e");
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Stack(
          children: [
            Center(child: CameraPreview(_cameraController!)),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isProcessing ? null : _captureAndUploadPhoto,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.primaryColor,
                      size: 35,
                    ),
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
