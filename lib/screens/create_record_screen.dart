import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import '../widgets/custom_center_title_button.dart';
import '../widgets/custom_dropdown_tile_single.dart';
import '../widgets/custom_fields.dart';
import '../widgets/entries_checkbox.dart';
import '../widgets/entries_image_container.dart';
import '../widgets/expandable_widget.dart';
import '../widgets/scrape_status_tile.dart';

class CreateRecordScreen extends StatefulWidget {
  final String entitiesId;

  const CreateRecordScreen({super.key, required this.entitiesId});

  @override
  State<CreateRecordScreen> createState() => _CreateRecordScreenState();
}

class _CreateRecordScreenState extends State<CreateRecordScreen> {
  // Her bölüm için açılma/kapanma durumları
  bool isMainInfoExpanded = true;
  bool isPulledListingsExpanded = false;
  bool isOtherInfoExpanded = false;
  bool isManualImagesExpanded = false;
  bool isScrapeDataExpanded = false;
  Map<String, dynamic>? entity;
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  Map<String, TextEditingController> _controllers = {};
  String? imageUrl = '';
  Map<String, bool> dynamicBooleans = {}; // Dinamik boolean değerlerini saklar
  Map<String, dynamic> imageValues = {};

  @override
  void initState() {
    _retrieveEntity();
    super.initState();
  }

  Future<void> _retrieveEntity() async {
    entity =
        await EntitiesService().retrieveEntities(context, widget.entitiesId);
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

        entity!['groupedAttributes'].forEach((key, value) {
          if (!_controllers.containsKey(key)) {
            _controllers[key] = TextEditingController(text: value?.toString());
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                TextConstants.newRecord,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2, // En fazla üç satır
                overflow: TextOverflow.ellipsis, // Taşan metin için üç nokta
              ),
            ),
            const SizedBox(width: 10,),
            Row(
              children: [
                HeaderIcon(letter: 'M', onTap: () {}),
                const SizedBox(width: 6),
                HeaderIcon(letter: 'O', onTap: () {}),
                const SizedBox(width: 6),
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
              child: entity == null
                  ? const Center(
                      child: SpinKitThreeBounce(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ),
                    )
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
                                          _controllers.remove(key);
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
                                  isExpanded: index + 1 < isExpandedList.length
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
                                                combinedList[index]['title'] ??
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
                                  isScrapeDataExpanded = !isScrapeDataExpanded;
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
    );
  }

  Widget buildAttributeWidget(
      Map<String, dynamic> attribute, VoidCallback? onDelete) {
    String attributeName = attribute['name'];

    // Eğer controller zaten varsa, mevcut controller'ı kullan
    if (!_controllers.containsKey(attributeName)) {
      _controllers[attributeName] = TextEditingController();
    } else if (!dynamicBooleans.containsKey(attributeName)) {
      dynamicBooleans[attributeName] = true;
    } else if (!imageValues.containsKey(attributeName)) {
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
        if (attributeName == "Scrape Status") {
          return EntriesScrapeStatusTile(
            label: attributeName,
            title: _controllers[attributeName]!.text,
            options:
                attribute['options'] != null && attribute['options'].isNotEmpty
                    ? attribute['options']
                    : TextConstants.emptyList,
            controller: _controllers[attributeName]!,
          );
        } else {
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
          onChanged: (value) {},
        );
      case 'image':
        if (imageValues[attributeName] is String &&
            imageValues[attributeName]!.isNotEmpty) {
          return EntriesImageContainer(
            label: attributeName,
            imageUrl: imageValues[attributeName] ?? '',
            onDelete: () {},
          );
        } else {
          return const SizedBox();
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
