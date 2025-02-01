import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/constants/app_colors.dart';
import 'package:flutter_pkgscan/widgets/scrape_status_tile.dart';
import '../services/cloud_service.dart';
import '../services/record_service.dart';
import '../utils/image_utils.dart';
import 'custom_center_title_button.dart';
import 'custom_dropdown_tile_single.dart';
import 'custom_fields.dart';
import 'entries_checkbox.dart';
import 'entries_image_container.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'snack_bar.dart';

// İlgili widget'ları ve yardımcı fonksiyonları burada tanımlıyoruz
class AttributeWidgets {
  static Widget buildAttributeWidget({
    required Map<String, dynamic> attribute,
    required Map<String, TextEditingController> controllers,
    required Map<String, dynamic> dynamicBooleans,
    required Map<String, String> imageValues,
    required Map<String, dynamic> oldImageValues,
    required String header,
    required String entitiesId,
    required String recordId,
    required ValueChanged onChanged,
    required VoidCallback onDelete,
    required BuildContext context,
  }) {
    final String attributeName = attribute['name'];

    // Eğer controller yoksa, yeni bir tane oluştur
    if (!controllers.containsKey(attributeName)) {
      controllers[attributeName] = TextEditingController();
    }

    // Attribute türüne göre uygun widget'ı döndür
    switch (attribute['type']) {
      case 'string':
      case 'richtext':
      case 'hyperlink':
      case 'real':
        return CustomFieldWithoutIcon(
          label: attributeName,
          controller: controllers[attributeName]!,
        );

      case 'integer':
        return CustomFieldWithoutIcon(
          label: attributeName,
          controller: controllers[attributeName]!,
          textInputType: TextInputType.number,
        );

      case 'single_choice':
        return buildSingleChoiceWidget(
            attributeName, attribute, controllers, context);

      case 'boolean':
        return buildBooleanWidget(
            attributeName, dynamicBooleans, context, onChanged);

      case 'image':
        return ImageUploadWidget(
          recordId: recordId,
          entitiesId: entitiesId,
          attributeName: attributeName,
          header: header,
          imageValues: imageValues,
          oldImageValues: oldImageValues,
          onDelete: onDelete,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  static Widget buildSingleChoiceWidget(
    String attributeName,
    Map<String, dynamic> attribute,
    Map<String, TextEditingController> controllers,
    BuildContext context,
  ) {
    final options = attribute['options'] ?? ['Empty List'];
    if (attributeName == "Scrape Status") {
      return EntriesScrapeStatusTile(
        label: attributeName,
        title: controllers[attributeName]!.text,
        options: options,
        controller: controllers[attributeName]!,
      );
    } else {
      return CustomDropdownTileSingle(
        label: attributeName,
        title: controllers[attributeName]!.text,
        options: options,
        controller: controllers[attributeName]!,
      );
    }
  }

  static Widget buildBooleanWidget(
    String attributeName,
    Map<String, dynamic> dynamicBooleans,
    BuildContext context,
    ValueChanged onChanged,
  ) {
    return EntriesCheckbox(
      isChecked: dynamicBooleans[attributeName] ?? false,
      label: attributeName,
      onChanged: onChanged,
    );
  }
}

class ImageUploadWidget extends StatefulWidget {
  final String attributeName;
  final String header;
  final Map<String, String> imageValues;
  final Map<String, dynamic> oldImageValues;
  final String entitiesId;
  final String recordId;
  final VoidCallback onDelete;

  const ImageUploadWidget({
    required this.attributeName,
    required this.header,
    required this.imageValues,
    required this.oldImageValues,
    required this.entitiesId,
    required this.recordId,
    required this.onDelete,
  });

  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  @override
  Widget build(BuildContext context) {
    // İlgili attributeName için imageValues'daki veri sayısını alıyoruz
    final images = widget.imageValues[widget.attributeName];

    // Attribute name kontrolü: "Manual Images" içeren alanları kontrol et
    if (widget.attributeName.contains("Manual Image")) {
      // Eğer Manual Image 1-10 varsa, dolu olanları göstereceğiz.
      final imageKey = widget.attributeName;
      final images = widget.imageValues[imageKey];

      if (images != null && images.isNotEmpty) {
        // Eğer bu alan doluysa, resimleri göster
        List<String> imageUrls = images.split(',');
        return Column(
          children: List.generate(
            imageUrls.length,
            (index) {
              return EntriesImageContainer(
                label: widget.attributeName,
                imageUrl: imageUrls[index],
                onDelete: widget.onDelete,
              );
            },
          ),
        );
      } else {
        // Eğer bu alan boşsa, "No Image" göster
        return SizedBox.shrink();
      }
    } else {
      // "Manual Image" içermeyen diğer alanlar için normal bir image container göster
      final images = widget.imageValues[widget.attributeName];

      if (images != null && images.isNotEmpty) {
        List<String> imageUrls = images.split(',');
        return Column(
          children: List.generate(
            imageUrls.length,
            (index) {
              return EntriesImageContainer(
                label: widget.attributeName,
                imageUrl: imageUrls[index],
                onDelete: widget.onDelete,
              );
            },
          ),
        );
      } else {
        return CustomCenterTitleButton(
          title: "Add Image",
          onTap: () => handleImageUpload(),
          icon: Icons.image,
          iconColor: Colors.blue,
          titleColor: Colors.blue,
        );
      }
    }
  }

  Future<void> handleImageUpload() async {
    final ImagePicker _picker = ImagePicker();
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
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        File selectedImage = File(image.path);

        // Fotoğraf işlemi başlar başlamaz yükleme diyalogunu açıyoruz
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Text(
                      "Uploading Image...",
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        try {
          // Fotoğraf sıkıştırma işlemi başlatılıyor
          File compressedImage = await compressImage(selectedImage);

          // Fotoğraf yükleme işlemi başlatılıyor
          final String? imageUrl = await CloudService()
              .uploadPhotoToCloud(context, compressedImage.path);

          Navigator.of(context).pop(); // Yükleme diyalogunu kapat

          if (imageUrl != null) {
            debugPrint("Image URL: $imageUrl");
            showSnackBar(
                context, "Image uploaded successfully! URL: $imageUrl");

            // Veritabanını güncelliyoruz
            RecordService().updateRecord(
              context,
              widget.entitiesId,
              widget.recordId,
              {widget.attributeName: imageUrl},
              widget.oldImageValues,
            );

            setState(() {
              widget.imageValues[widget.attributeName] = imageUrl;
            });
          } else {
            showSnackBar(context, 'Image upload failed.');
          }
        } catch (e) {
          Navigator.of(context).pop(); // Yükleme diyalogunu kapat
          showSnackBar(context, "Error during upload: $e");
        }
      }
    }
  }
}
