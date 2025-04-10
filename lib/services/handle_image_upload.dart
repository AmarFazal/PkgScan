import 'package:flutter/material.dart';
import '../services/record_service.dart';
import '../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../widgets/snack_bar.dart';
import 'cloud_service.dart';

Future<List<String>?> handleImageUpload(
    BuildContext context,
    String entitiesId,
    String? recordId,
    List<String> emptyAttributeNames,
    Map oldImageValues,
    Map imageValues,
    Function(String attributeName, String imageUrl) onImageUploaded, // Callback fonksiyonu
    Map<String, bool> isLoadingMap, // Yükleme durumlarını tutacak Map
    bool isNew,
    ) async {
  final ImagePicker _picker = ImagePicker();

  // Kullanıcıya galeriden veya kameradan seçim yapma seçeneği sun
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SizedBox(
      height: 100,
      child: BottomSheet(
        builder: (context) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              child: const Text("Select from Gallery"),
              onPressed: () {
                Navigator.of(context).pop(ImageSource.gallery);
              },
            ),
            TextButton(
              child: const Text("Capture with Camera"),
              onPressed: () {
                Navigator.of(context).pop(ImageSource.camera);
              },
            ),
          ],
        ),
        onClosing: () {},
      ),
    ),
  );

  if (source != null) {
    List<XFile>? images;

    if (source == ImageSource.gallery) {
      // Galeriden birden fazla fotoğraf seç
      images = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } else if (source == ImageSource.camera) {
      // Kameradan tek bir fotoğraf seç
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        images = [image];
      }
    }
    for (var emptyAttributeName in emptyAttributeNames.take(images!.length)) {
      isLoadingMap[emptyAttributeName] = true;
    }

    if (images != null && images.isNotEmpty) {
      if (images.length > 10) {
        showSnackBar(context: context, message: "You can select up to 10 images.");
        images = images.sublist(0, 10);
      }

      if (emptyAttributeNames.length < images.length) {
        showSnackBar(context: context, message: "Not enough empty Manual Image slots available.");
        return null;
      }

      try {
        List<String> uploadedImageUrls = [];

        // **Fotoğraflar seçildiği anda yükleme durumunu true yap**


        // **Cloud'a yükleme işlemi burada başlıyor**
        for (int i = 0; i < images.length; i++) {
          final emptyAttributeName = emptyAttributeNames[i];

          File selectedImage = File(images[i].path);
          File compressedImage = await compressImage(selectedImage);
          final String? imageUrl = await CloudService()
              .uploadPhotoToCloud(context, compressedImage.path);

          if (imageUrl != null) {
            // Callback fonksiyonunu çağır
            onImageUploaded(emptyAttributeName, imageUrl);

            isNew==false?await RecordService().updateRecord(
              context,
              entitiesId,
              recordId,
              {emptyAttributeName: imageUrl},
              oldImageValues,
            ):null;

            uploadedImageUrls.add(imageUrl);
          }

          // **Yükleme tamamlandıktan sonra false yap**
          isLoadingMap[emptyAttributeName] = false;
        }
        showSnackBar(context: context, message: "${images.length} images uploaded successfully!");
        return uploadedImageUrls;
      } catch (e) {
        showSnackBar(context: context, message: "Error during upload: $e");
        return null;
      }
    }

  }

  return null;
}