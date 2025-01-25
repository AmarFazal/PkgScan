import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/services/entities_service.dart';
import 'package:flutter_pkgscan/widgets/custom_center_title_button.dart';
import 'package:flutter_pkgscan/widgets/custom_dropdown_tile_single.dart';
import 'package:flutter_pkgscan/widgets/dialogs/save_record_dialog.dart';
import 'package:flutter_pkgscan/widgets/entries_checkbox.dart';
import 'package:flutter_pkgscan/widgets/entries_image_container.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/record_service.dart';
import '../widgets/custom_fields.dart';
import '../widgets/expandable_widget.dart';
import '../widgets/scrape_status_tile.dart';

class RecordScreen extends StatefulWidget {
  final String entitiesId;
  final String recordId;
  final int index;
  final bool isNew;

  const RecordScreen({super.key, required this.isNew, required this.entitiesId, required this.recordId, required this.index});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  // Her bölüm için açılma/kapanma durumları
  bool isMainInfoExpanded = true;
  bool isPulledListingsExpanded = false;
  bool isOtherInfoExpanded = false;
  bool isManualImagesExpanded = false;
  bool isScrapeDataExpanded = false;
  bool? isChecked = false;
  final EntitiesService _entitiesService = EntitiesService();
  Map<String, dynamic>? entity;
  Map<String, dynamic>? allRecords; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  Map<String, TextEditingController> _controllers = {};
  String? imageUrl = '';
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {}; // Dinamik boolean değerlerini saklar
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, dynamic> imageValues = {};
  Map<String, dynamic> oldImageValues = {};

  @override
  void initState() {
    _fetchRecordData();
    _retrieveEntity();
    // debugPrint("Entity ID: ${widget.entitiesId}");
    // debugPrint('Record ID: ${widget.recordId}');
    // debugPrint("Index Of Record is: ${widget.index}");
    super.initState();
  }

  // Method to handle sending updated data
  void sendUpdatedData(String key, Map<String, dynamic> newValue) {
    // log("Updated Key: $key, New Value: $newValue");
    RecordService()
        .updateRecord(context, widget.entitiesId, key, newValue, oldValues);
  }

  // Method to check if there are changes
  void checkForChanges(String key, Map<String, dynamic> newValue) {
    String? oldValue = oldValues[key];
    if (oldValue != null && oldValue != newValue) {
      sendUpdatedData(key, newValue);
      oldValues[key] = newValue;
    }
  }

  // Method to check if there are changes
  void checkBooleanForChanges(String key, Map<String, dynamic> newValue) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      debugPrint("Boolean New Value: $newValue");
      RecordService().updateRecord(context, widget.entitiesId, widget.recordId,
          newValue, oldBooleanValues);
      setState(() {
        oldBooleanValues[key] = newValue;
      });
    }
  }

  void checkImageForChanges(String key, Map<String, dynamic> newValue) {
    if (oldImageValues[key] != null && oldImageValues[key] != newValue) {
      debugPrint("Boolean New Value: $newValue");
      RecordService().updateRecord(context, widget.entitiesId, widget.recordId,
          newValue, oldImageValues);
      setState(() {
        oldImageValues[key] = newValue;
      });
    }
  }

  void saveData() {
    // Iterate through all the controllers and collect the updated data
    Map<String, dynamic> updatedData = {};

    _controllers.forEach((key, controller) {
      updatedData[key] =
          controller.text; // Assuming the value is in the controller's text
    });

    // Send the updated data
    sendUpdatedData(widget.recordId, updatedData);
    // Optionally, show a confirmation or success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully!")),
    );
    Navigator.pop(context);
  }

  Future<void> _fetchRecordData() async {
    final data = await RecordService().retrieveRecords(
        context, widget.entitiesId ?? 'Somethings went wrong', '');
    final record = data[0]['records'][widget.index];
    setState(() {
      if (data != null) {
        allRecords = record;

        imageUrl = record["data"]['Pulled Images'] ?? '';

        // Dinamik olarak controller'ları oluştur
        record['data'].forEach((key, value) {
          if (!_controllers.containsKey(key)) {
            _controllers[key] = TextEditingController(text: value?.toString());
            oldValues[key] = value?.toString() ?? '';
          }
        });

        // Dinamik olarak controller'ları oluştur
        record['data'].forEach((key, value) {
          if (!dynamicBooleans.containsKey(key)) {
            // String değeri bool'a dönüştürmek için kontrol
            if (value is String) {
              dynamicBooleans[key] = value.toLowerCase() == 'true';
            } else if (value is bool) {
              dynamicBooleans[key] = value;
            } else {
              // Eğer value ne String ne de bool ise, bir varsayılan değer kullanabilirsiniz
              dynamicBooleans[key] = false;
            }
            oldBooleanValues[key] =
                value is bool ? value : value?.toString() ?? '';
          }
        });



        record['data'].forEach((key, value) {
          if (!imageValues.containsKey(key)) {
            // String değeri bool'a dönüştürmek için kontrol
            if (value is String) {
              imageValues[key] = value;
            } else {
              // Eğer value ne String ne de bool ise, bir varsayılan değer kullanabilirsiniz
              imageValues[key] = "";
            }
            imageValues[key] =
            value is String ? value : value?.toString() ?? '';
          }
        });

        List<String> imageKeys = record['data']
            .keys
            .where((key) => key is String && key.startsWith("Image "))
            .cast<String>()
            .toList();

        List<String> titleKeys = record['data']
            .keys
            .where((key) => key is String && key.startsWith("Title "))
            .cast<String>()
            .toList();

        List<String> msrpKeys = record['data']
            .keys
            .where((key) => key is String && key.startsWith("MSRP "))
            .cast<String>()
            .toList();

        imageKeys.sort();
        titleKeys.sort();
        msrpKeys.sort();

        combinedList = [];

        for (int i = 0; i < imageKeys.length; i++) {
          String? imageUrl = record["data"][imageKeys[i]]?.toString() ?? '';
          String? title = i < titleKeys.length
              ? record["data"][titleKeys[i]]?.toString() ?? ''
              : '';
          String? msrp = i < msrpKeys.length
              ? record["data"][msrpKeys[i]]?.toString() ?? ''
              : '';

          if (imageUrl.isNotEmpty || title.isNotEmpty || msrp.isNotEmpty) {
            combinedList.add({
              'image': imageUrl,
              'title': title,
              'msrp': msrp,
            });
          }
        }

        // Her "Pulled Listing" için bir bool değeri ekle
        isExpandedList = List<bool>.filled(combinedList.length, false);
      }
      isLoading = false;
    });
  }

  Future<void> _retrieveEntity() async {
    entity =
        await _entitiesService.retrieveEntities(context, widget.entitiesId);
    if (entity != null) {
      setState(() {
        entity!['groupedAttributes']?.forEach((key, attributes) {
          attributes.forEach((attribute) {
            if (attribute['type'] == 'boolean' && attribute['key'] != null) {
              // Eğer boolean tipindeyse, varsayılan değer olarak `false` atanır
              dynamicBooleans[attribute['key']] = attribute['value'] ?? false;
              debugPrint(
                  "Dinamik Boolean Oluşturuldu: ${attribute['key']} = ${dynamicBooleans[attribute['key']]}");
            }
            if (attribute['type'] == 'image' && attribute['key'] != null) {
              // Eğer boolean tipindeyse, varsayılan değer olarak `false` atanır
              imageValues[attribute['key']] = attribute['value'] ?? '';
              debugPrint(
                  "Dinamik image Oluşturuldu: ${attribute['key']} = ${imageValues[attribute['key']]}");
            }
          });
        });
      });
    } else {
      debugPrint('Failed to retrieve entity.');
    }
  }

  bool _hasUnsavedChanges() {
    log("${_controllers.keys}");
    for (var key in _controllers.keys) {
      if (_controllers[key]?.text != oldValues[key]) {
        return true; // Bir değişiklik varsa true döner
      }
    }
    for (var key in dynamicBooleans.keys) {
      if (dynamicBooleans[key] != oldBooleanValues[key]) {
        return true; // Boolean değişiklik varsa true döner
      }
    }
    for (var key in imageValues.keys) {
      if (imageValues[key] != oldImageValues[key]) {
        return true; // Boolean değişiklik varsa true döner
      }
    }
    return false; // Hiç değişiklik yoksa false döner
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showSaveRecordDialog(
          context: context,
          onTapCancel: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onTapSave: () {
            saveData(); // Değişiklikleri kaydet
            Navigator.of(context).pop(true);
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool hasChanges = _hasUnsavedChanges();
        if (hasChanges) {
          return await _showUnsavedChangesDialog(context);
        }
        return true; // Değişiklik yoksa çıkışa izin ver
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.isNew
                      ? TextConstants.newRecord
                      : TextConstants.editRecord,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2, // En fazla üç satır
                  overflow: TextOverflow.ellipsis, // Taşan metin için üç nokta
                ),
              ),
              Row(
                children: [
                  HeaderIcon(
                      letter: 'M',
                      onTap: () {
                        saveData();
                      }),
                  const SizedBox(width: 16),
                  HeaderIcon(letter: 'O', onTap: () {}),
                  const SizedBox(width: 16),
                  HeaderIcon(letter: 'P', onTap: () {}),
                ],
              )
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: entity == null || allRecords == null
                    ?
                    // Veri henüz yüklenmedi, bir yüklenme göstergesi göster
                    const Center(
                        child: SpinKitThreeBounce(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 20),
                          ...entity?['subheaderOrder']?.map<Widget>((header) {
                            if (header == 'Main Information') {
                              return buildExpandableSection(
                                title: header,
                                isExpanded: isMainInfoExpanded,
                                onToggle: () {
                                  setState(() {
                                    isMainInfoExpanded = !isMainInfoExpanded;
                                  });
                                },
                                children: entity!['groupedAttributes'][header]
                                    .map<Widget>((attribute) {
                                  return buildAttributeWidget(
                                    attribute,
                                    () {},
                                  );
                                }).toList(),
                                context: context,
                              );
                            } else if (header == 'Manual Images') {
                              return buildExpandableSection(
                                title: header,
                                isExpanded: isManualImagesExpanded,
                                onToggle: () {
                                  setState(() {
                                    isManualImagesExpanded =
                                        !isManualImagesExpanded;
                                  });
                                },
                                children: entity!['groupedAttributes'][header]
                                    .map<Widget>((attribute) {
                                  return buildAttributeWidget(
                                    attribute,
                                    () {
                                      setState(() {
                                        _controllers.forEach((key, controller) {
                                          if (key == attribute['name']) {
                                            _controllers
                                                .remove(key);
                                            log("cont$key ${controller.text}");
                                          }
                                        });
                                        entity!['groupedAttributes'][header]
                                            .remove(attribute);
                                        log("Attribute removed: $attribute");
                                      });
                                    },
                                  );
                                }).toList(),
                                context: context,
                              );
                            } else if (header == 'Online Pulled Listings') {
                              if (isExpandedList.length <
                                  combinedList.length + 1) {
                                // Liste boyutunu kontrol et ve yeniden oluştur
                                isExpandedList =
                                    List.filled(combinedList.length + 1, false);
                              }

                              return buildExpandableSection(
                                title: 'Online Pulled Listings',
                                isExpanded: isExpandedList[0],
                                onToggle: () {
                                  setState(() {
                                    isExpandedList[0] = !isExpandedList[0];
                                  });
                                },
                                children: combinedList
                                    .asMap()
                                    .entries
                                    .map<Widget>((entry) {
                                  int index = entry.key;
                                  Map<String, String> listing = entry.value;

                                  return buildExpandableSection(
                                    title: 'Pulled Listing ${index + 1}',
                                    isExpanded:
                                        index + 1 < isExpandedList.length
                                            ? isExpandedList[index + 1]
                                            : false,
                                    onToggle: () {
                                      setState(() {
                                        if (index + 1 < isExpandedList.length) {
                                          isExpandedList[index + 1] =
                                              !isExpandedList[index + 1];
                                        }
                                      });
                                    },
                                    children: [
                                      if (listing['image'] != null &&
                                          listing['image']!.isNotEmpty)
                                        EntriesImageContainer(
                                          label: TextConstants.onlineImage,
                                          imageUrl: listing['image']!,
                                          onDelete: () {
                                            log("listin image");
                                          },
                                        ),
                                      if (listing['msrp'] != null &&
                                          listing['msrp']!.isNotEmpty)
                                        CustomFieldWithoutIcon(
                                          label: TextConstants.msrp,
                                          controller: TextEditingController(
                                              text: listing['msrp']),
                                        ),
                                      if (listing['title'] != null &&
                                          listing['title']!.isNotEmpty)
                                        CustomFieldWithoutIcon(
                                          label: TextConstants.title,
                                          controller: TextEditingController(
                                              text: listing['title']),
                                        ),
                                      CustomCenterTitleButton(
                                        title: TextConstants.keepAllData,
                                        icon: Icons.check_circle,
                                        onTap: () {
                                          // Keep All Data işlemi
                                          setState(() {
                                            // Örnek: İlk pulled listing'deki veriyi, Main Information'a aktarma
                                            if (combinedList.isNotEmpty) {
                                              // Main Information'daki title, msrp ve image controller'larını güncelle
                                              _controllers['Title']?.text =
                                                  combinedList[index]
                                                          ['title'] ??
                                                      '';
                                              _controllers['MSRP']?.text =
                                                  combinedList[index]['msrp'] ??
                                                      '';
                                              imageUrl = combinedList[index]
                                                      ['image'] ??
                                                  ''; // pulled listing'deki image URL'sini güncelle
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                    context: context,
                                  );
                                }).toList(),
                                context: context,
                              );
                            } else if (header == 'Other Information') {
                              return buildExpandableSection(
                                title: header,
                                isExpanded: isOtherInfoExpanded,
                                onToggle: () {
                                  setState(() {
                                    isOtherInfoExpanded = !isOtherInfoExpanded;
                                  });
                                },
                                children: entity!['groupedAttributes'][header]
                                    .map<Widget>((attribute) {
                                  return buildAttributeWidget(
                                    attribute,
                                    () {},
                                  );
                                }).toList(),
                                context: context,
                              );
                            } else if (header == 'Scrape Data') {
                              return buildExpandableSection(
                                title: header,
                                isExpanded: isScrapeDataExpanded,
                                onToggle: () {
                                  setState(() {
                                    isScrapeDataExpanded =
                                        !isScrapeDataExpanded;
                                  });
                                },
                                children: entity!['groupedAttributes'][header]
                                    .map<Widget>((attribute) {
                                  return buildAttributeWidget(
                                    attribute,
                                    () {},
                                  );
                                }).toList(),
                                context: context,
                              );
                            } else {
                              // Eğer header tanınmıyorsa, boş bir widget döner
                              return const SizedBox.shrink();
                            }
                          }).toList(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated buildAttributeWidget to use controllers
  Widget buildAttributeWidget(
      Map<String, dynamic> attribute, VoidCallback? onDelete) {
    String attributeName = attribute['name'];

    // Eğer controller zaten varsa, mevcut controller'ı kullan
    if (!_controllers.containsKey(attributeName)) {
      _controllers[attributeName] = TextEditingController();
    } else if (!dynamicBooleans.containsKey(attributeName)) {
      dynamicBooleans[attributeName] = true;
    }else if (!imageValues.containsKey(attributeName)) {
      imageValues[attributeName] = true;
    }

    switch (attribute['type']) {
      case 'string':
        return CustomFieldWithoutIcon(
          label: attributeName,
          controller: _controllers[attributeName]!,
        );
      case 'integer':
        return CustomFieldWithoutIcon(
          label: attributeName,
          controller: _controllers[attributeName]!,
          textInputType: TextInputType.number,
        );
      case 'single_choice':
         if(attributeName == "Scrape Status"){
          return EntriesScrapeStatusTile(
            label: attributeName,
            title: _controllers[attributeName]!.text,
            options:
            attribute['options'] != null && attribute['options'].isNotEmpty
                ? attribute['options']
                : TextConstants.emptyList,
            controller: _controllers[attributeName]!,
          );
        }else{
           return CustomDropdownTileSingle(
            label: attributeName,
            title: _controllers[attributeName]!.text,
            options:
            attribute['options'] != null && attribute['options'].isNotEmpty
                ? attribute['options']
                : TextConstants.emptyList,
            controller: _controllers[attributeName]!,
          );

        }
      case 'boolean':
        return EntriesCheckbox(
          isChecked: dynamicBooleans[attributeName] ?? false,
          // boolean tipi için true/false değeri dinamik olmalı
          label: attributeName,
          onChanged: (value) {
            setState(() {
              dynamicBooleans[attributeName] = value;
            });
            checkBooleanForChanges(attributeName, {attributeName: value});
          },
        );
      case 'image':
        if (imageValues[attributeName] is String && imageValues[attributeName]!.isNotEmpty) {
          return EntriesImageContainer(
            label: attributeName,
            imageUrl: imageValues[attributeName] ?? '',
            onDelete: () { },
          );
        } else {
          return SizedBox();
        }


      case 'richtext':
      case 'hyperlink':
      case 'real':
        return CustomFieldWithoutIcon(
          label: attributeName,
          controller: _controllers[attributeName]!,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
