import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../services/manifest_service.dart';
import '../outlined_custom_tile.dart';

Future<void> showManifestSettingsDialog(
    {required BuildContext context,
    required String manifestId,
    required String initialName,
    required String initialDescription,
    required VoidCallback onTapSave,
    required VoidCallback onTapArchive,
    required VoidCallback onTapExport,
    }) async {
  showModalBottomSheet(
    isScrollControlled: true,
    // Klavye açıldığında ekranın tamamını kullanabilmesi için
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(30)), // Oval köşe
    ),
    backgroundColor: Colors.white,
    // Arka plan rengi
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
        ),
        child: SingleChildScrollView(
          // İçeriği kaydırılabilir hale getirir
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedCustomTile(
                title: "Edit",
                icon: Icons.edit,
                onTap: () {
                  Navigator.pop(context);
                  showEditManifestDialog(
                    context,
                    manifestId, // manifestId
                    initialName, // initialName
                    initialDescription,
                    onTapSave,
                  );
                },
              ),
              const SizedBox(height: 15),
              OutlinedCustomTile(
                title: "Delete",
                icon: Icons.delete,
                onTap: () {
                  Navigator.pop(context);
                  onTapArchive();
                },
              ),
              // const SizedBox(height: 15),
              // OutlinedCustomTile(
              //   title: "Export",
              //   icon: Icons.file_open,
              //   onTap: onTapExport,
              // ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      );
    },
  );
}

void showEditManifestDialog(BuildContext context, String manifestId,
    String initialName, String initialDescription, VoidCallback onTap) {
  final TextEditingController nameController =
      TextEditingController(text: initialName);
  final TextEditingController descriptionController =
      TextEditingController(text: initialDescription);

  showModalBottomSheet(
    isScrollControlled: true,
    // Klavye açıldığında ekranın tamamını kullanabilmesi için
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(30)), // Oval köşe
    ),
    backgroundColor: Colors.white,
    // Arka plan rengi
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
        ),
        child: SingleChildScrollView(
          // İçeriği kaydırılabilir hale getirir
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Manifest ismi için metin alanı
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.text_fields),
                  prefixIconColor: AppColors.primaryColor,
                  hintText: TextConstants.manifestName,
                  hintStyle: Theme.of(context).textTheme.displayMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              // Manifest açıklaması için metin alanı
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.description),
                  prefixIconColor: AppColors.primaryColor,
                  hintText: TextConstants.manifestDescription,
                  hintStyle: Theme.of(context).textTheme.displayMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              // İptal ve Ekle butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(TextConstants.cancel,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: AppColors.errorColor)),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Verilerinizi kaydedin
                      await ManifestService().editManifest(
                        context,
                        manifestId,
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                      );
                      Navigator.of(context).pop(); // Diyalog kutusunu kapat
                      onTap();
                    },
                    child: Text(TextConstants.save,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: AppColors.successColor)),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
