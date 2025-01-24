import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../services/manifest_service.dart';

Future<void> showAddManifestDialog({
  required BuildContext context,
  required Function(String, IconData?) onAdd,
  required List<Map<String, dynamic>> iconList,
}) async {
  TextEditingController manifestNameController = TextEditingController();
  TextEditingController manifestDescriptionController = TextEditingController();
  IconData? _selectedIcon;

  await showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      IconData? tempSelectedIcon = _selectedIcon;
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Manifest ismi için metin alanı
              TextField(
                controller: manifestNameController,
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
                controller: manifestDescriptionController,
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
              // Dropdown ile ikon seçme
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: StatefulBuilder(builder: (context, setDialogState) {
                  return DropdownButton<IconData>(
                    value: tempSelectedIcon ?? Icons.task_outlined,
                    hint: Text(TextConstants.selectAnIcon),
                    isExpanded: true,
                    elevation: 0,
                    borderRadius: BorderRadius.circular(25),
                    underline: SizedBox(),
                    items: iconList.map((Map<String, dynamic> icon) {
                      return DropdownMenuItem<IconData>(
                        value: icon['icon'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                icon['icon'],
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                icon['name'],
                                style:
                                    Theme.of(context).textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (icon) {
                      setDialogState(() {
                        tempSelectedIcon = icon;
                      });
                    },
                  );
                }),
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
                      if (manifestNameController.text.isNotEmpty) {
                        try {
                          // ManifestService'i çağırarak manifesti ekle
                          await ManifestService().addManifest(
                            context,
                            manifestNameController.text,
                            manifestDescriptionController.text,
                            // Burada açıklamayı da ekleyebilirsiniz
                            tempSelectedIcon ?? Icons.task_outlined,
                          );
                          onAdd(manifestNameController.text, tempSelectedIcon);
                          Navigator.pop(context);
                        } catch (e) {
                          // Hata durumunda kullanıcıya mesaj göster
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(TextConstants.add,
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
