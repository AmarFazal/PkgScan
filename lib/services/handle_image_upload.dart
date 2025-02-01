import 'package:flutter/material.dart';
import '../services/cloud_service.dart';
import '../services/record_service.dart';
import '../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../widgets/snack_bar.dart';

Future<List<String>?> handleImageUpload(
    BuildContext context,
    String entitiesId,
    String recordId,
    List<String> emptyAttributeNames,
    Map oldImageValues,
    Map imageValues,
    Function(String attributeName, String imageUrl) onImageUploaded, // Callback fonksiyonu
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

    if (images != null && images.isNotEmpty) {
      if (images.length > 10) {
        showSnackBar(context, "You can select up to 10 images.");
        images = images.sublist(0, 10);
      }

      if (emptyAttributeNames.length < images.length) {
        showSnackBar(context, "Not enough empty Manual Image slots available.");
        return null;
      }

      try {
        List<String> uploadedImageUrls = [];

        for (int i = 0; i < images.length; i++) {
          File selectedImage = File(images[i].path);
          File compressedImage = await compressImage(selectedImage);
          final String? imageUrl = await CloudService()
              .uploadPhotoToCloud(context, compressedImage.path);

          if (imageUrl != null) {
            final emptyAttributeName = emptyAttributeNames[i];
            // Callback fonksiyonunu çağır
            onImageUploaded(emptyAttributeName, imageUrl);

            await RecordService().updateRecord(
              context,
              entitiesId,
              recordId,
              {emptyAttributeName: imageUrl},
              oldImageValues,
            );

            uploadedImageUrls.add(imageUrl);
          }
        }
        showSnackBar(context, "${images.length} images uploaded successfully!");
        return uploadedImageUrls;
      } catch (e) {
        showSnackBar(context, "Error during upload: $e");
        return null;
      }
    }
  }

  return null;
}