import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/header_icon.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import '../services/record_service.dart';
import '../widgets/attribute_widgets.dart';
import '../widgets/custom_center_title_button.dart';
import '../widgets/custom_fields.dart';
import '../widgets/dialogs/save_record_dialog.dart';
import '../widgets/entries_image_container.dart';
import '../widgets/expandable_widget.dart';

class RecordScreen extends StatefulWidget {
  final String entitiesId;
  final String recordId;
  final int index;
  final bool isNew;

  const RecordScreen(
      {super.key,
      required this.isNew,
      required this.entitiesId,
      required this.recordId,
      required this.index});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool? isChecked = false;
  final EntitiesService _entitiesService = EntitiesService();
  final RecordService _recordService = RecordService();
  Map<String, dynamic>? entity;
  Map<String, dynamic>? allRecords; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {}; // Dinamik boolean değerlerini saklar
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, String> imageValues = {};
  Map<String, dynamic> oldImageValues = {};
  late Map<String, bool> expandedSections;

  @override
  void initState() {
    _fetchRecordData();
    _retrieveEntity();
    expandedSections = {
      'Main Information': true,
      'Manual Images': false,
      'Online Pulled Listings': false,
      'Other Information': false,
      'Scrape Data': false,
      // Add more sections here if needed
    };
    super.initState();
  }

  void toggleExpansion(String header) {
    setState(() {
      expandedSections[header] = !expandedSections[header]!;
    });
  }

  void checkImageForChanges(String key, Map<String, dynamic> newValue) {
    if (oldImageValues[key] != null && oldImageValues[key] != newValue) {
      debugPrint(
          "Image New Value: $newValue"); // Ensure image data is updated here
      _recordService.updateRecord(context, widget.entitiesId, widget.recordId,
          newValue, oldImageValues);
      setState(() {
        oldImageValues[key] = newValue; // Make sure to update oldImageValues
      });
    }
  }

  // Method to check if there are changes
  void checkBooleanForChanges(String key, Map<String, dynamic> newValue) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      debugPrint("Boolean New Value: $newValue");
      _recordService.updateRecord(context, widget.entitiesId, widget.recordId,
          newValue, oldBooleanValues);
      setState(() {
        oldBooleanValues[key] = newValue;
      });
    }
  }

  // Method to handle sending updated data
  void sendUpdatedData(String key, Map<String, dynamic> newValue) {
    _recordService.updateRecord(
        context, widget.entitiesId, key, newValue, oldValues);
  }

// Save the data collected from controllers and update the record
  void saveData() {
    // Collect the updated data from all controllers
    Map<String, dynamic> updatedData = _controllers.map((key, controller) {
      return MapEntry(key, controller.text);
    });

    imageValues.forEach((key, value) {
      if (value.isNotEmpty) {
        updatedData[key] = value;
      }
    });
    _controllers.forEach((key, controller) {
      updatedData[key] =
          controller.text; // Assuming the value is in the controller's text
    });

    // Send the updated data to the server
    sendUpdatedData(widget.recordId, updatedData);

    // Show a confirmation message and close the screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully!")),
    );
    Navigator.pop(context);
  }

// Fetch the record data and update state with the retrieved values
  Future<void> _fetchRecordData() async {
    final data = await _recordService.retrieveRecords(
        context, widget.entitiesId ?? 'Somethings went wrong', '');

    if (data != null && data.isNotEmpty) {
      final record = data[0]['records'][widget.index];
      setState(() {
        allRecords = record;

        // Initialize controllers, boolean values, and image values dynamically
        _initializeControllers(record['data']);
        _initializeDynamicBooleans(record['data']);
        _initializeImageValues(record['data']);

        // Organize and sort keys for dynamic lists
        _prepareCombinedList(record['data']);
      });
    }
  }

// Initialize the text controllers for each field dynamically
  void _initializeControllers(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (!_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController(text: value?.toString());
        oldValues[key] = value?.toString() ?? '';
      }
    });
  }

// Initialize the dynamic boolean values based on the data
  void _initializeDynamicBooleans(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (!dynamicBooleans.containsKey(key)) {
        dynamicBooleans[key] = _parseBoolean(value);
        oldBooleanValues[key] = value?.toString() ?? '';
      }
    });
  }

// Initialize image values based on the data
  void _initializeImageValues(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (!imageValues.containsKey(key)) {
        imageValues[key] = value?.toString() ?? '';
      }
    });
  }

// Parse the value to a boolean (handles both string and boolean types)
  bool _parseBoolean(dynamic value) {
    if (value is String) {
      return value.toLowerCase() == 'true';
    } else if (value is bool) {
      return value;
    }
    return false;
  }

// Prepare a combined list of image, title, and MSRP keys
  void _prepareCombinedList(Map<String, dynamic> data) {
    List<String> imageKeys = _getSortedKeysStartingWith(data, "Image ");
    List<String> titleKeys = _getSortedKeysStartingWith(data, "Title ");
    List<String> msrpKeys = _getSortedKeysStartingWith(data, "MSRP ");

    combinedList = [];
    for (int i = 0; i < imageKeys.length; i++) {
      String imageUrl = data[imageKeys[i]]?.toString() ?? '';
      String title =
          i < titleKeys.length ? data[titleKeys[i]]?.toString() ?? '' : '';
      String msrp =
          i < msrpKeys.length ? data[msrpKeys[i]]?.toString() ?? '' : '';

      if (imageUrl.isNotEmpty || title.isNotEmpty || msrp.isNotEmpty) {
        combinedList.add({
          'image': imageUrl,
          'title': title,
          'msrp': msrp,
        });
      }
    }

    // Expand the list for each pulled listing
    isExpandedList = List<bool>.filled(combinedList.length, false);
  }

// Retrieve sorted keys starting with the specified prefix
  List<String> _getSortedKeysStartingWith(
      Map<String, dynamic> data, String prefix) {
    return data.keys
        .where((key) => key is String && key.startsWith(prefix))
        .cast<String>()
        .toList()
      ..sort();
  }

// Retrieve the entity and initialize boolean/image values for attributes
  Future<void> _retrieveEntity() async {
    entity =
        await _entitiesService.retrieveEntities(context, widget.entitiesId);
    if (entity != null) {
      setState(() {
        entity!['groupedAttributes']?.forEach((key, attributes) {
          attributes.forEach((attribute) {
            if (attribute['type'] == 'boolean' && attribute['key'] != null) {
              dynamicBooleans[attribute['key']] = attribute['value'] ?? false;
            }
            if (attribute['type'] == 'image' && attribute['key'] != null) {
              imageValues[attribute['key']] = attribute['value'] ?? '';
            }
          });
        });
      });
    } else {
      debugPrint('Failed to retrieve entity.');
    }
  }

// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    for (var key in _controllers.keys) {
      if (_controllers[key]?.text != oldValues[key]) {
        return true;
      }
    }
    for (var key in dynamicBooleans.keys) {
      if (dynamicBooleans[key] != oldBooleanValues[key]) {
        return true;
      }
    }
    for (var key in imageValues.keys) {
      if (imageValues[key] != oldImageValues[key]) {
        return true;
      }
    }
    return false;
  }

// Show a dialog if there are unsaved changes
  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showSaveRecordDialog(
          context: context,
          onTapCancel: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onTapSave: () {
            saveData();
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
        return true;
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                    ? const Center(
                        child: SpinKitThreeBounce(
                            color: AppColors.primaryColor, size: 30.0))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 20),
                          if (entity != null)
                            ...entity!['subheaderOrder']?.map<Widget>((header) {
                              bool isExpanded =
                                  expandedSections[header] ?? false;

                              if (header == 'Main Information') {
                                return buildExpandableSection(
                                  title: header,
                                  isExpanded: isExpanded,
                                  onToggle: () => toggleExpansion(header),
                                  children: [
                                    // Main Information için normal attribute'lar
                                    ...entity!['groupedAttributes'][header]
                                        .map<Widget>((attribute) {
                                      return AttributeWidgets
                                          .buildAttributeWidget(
                                        context: context,
                                        attribute: attribute,
                                        header: header,
                                        controllers: _controllers,
                                        dynamicBooleans: dynamicBooleans,
                                        imageValues: imageValues,
                                        oldImageValues: oldImageValues,
                                        entitiesId: entity!["_id"],
                                        recordId: widget.recordId,
                                        onChanged: (value) {
                                          setState(() {
                                            dynamicBooleans[attribute['name']] =
                                                value;
                                          });
                                          checkBooleanForChanges(
                                              attribute['name'],
                                              {attribute['name']: value});
                                        },
                                        onDelete: () {
                                          setState(() {
                                            oldImageValues[attribute['name']] =
                                                imageValues[attribute['name']] =
                                                    '';
                                            checkImageForChanges(
                                                attribute['name'],
                                                {attribute['name']: ''});
                                          });
                                        },
                                      );
                                    }).toList(),
                                    Container(
                                      margin: const EdgeInsets.only(
                                        top: 0,
                                        bottom: 20,
                                      ),
                                      padding: const EdgeInsets.only(
                                        top: 0,
                                        bottom: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryColor,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 14, top: 8),
                                            child: Text(
                                              "Manual Images",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                      color:
                                                          AppColors.textColor,
                                                      fontSize: 13),
                                            ),
                                          ),
                                          SizedBox(
                                            height:
                                                200, // Fotoğrafların yüksekliği
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              // Yatay kaydırma
                                              itemCount:
                                                  entity!['groupedAttributes']
                                                              ['Manual Images']
                                                          .length +
                                                      1,
                                              // +1 ekledik (Add Image butonu için)
                                              itemBuilder: (context, index) {
                                                if (index ==
                                                    entity!['groupedAttributes']
                                                            ['Manual Images']
                                                        .length) {
                                                  // Son eleman, Add Image butonu olacak
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      // Boş olan Manual Image'i bul
                                                      String?
                                                          emptyAttributeName;
                                                      for (var attribute in entity![
                                                              'groupedAttributes']
                                                          ['Manual Images']) {
                                                        final attributeName =
                                                            attribute['name'];
                                                        final imageValue =
                                                            imageValues[
                                                                attributeName];
                                                        if ((imageValue ==
                                                                    null ||
                                                                imageValue
                                                                    .isEmpty) &&
                                                            attributeName.contains(
                                                                "Manual Image")) {
                                                          emptyAttributeName =
                                                              attributeName;
                                                          break; // İlk boş olanı bulduktan sonra döngüyü kırıyoruz
                                                        }
                                                      }

                                                      if (emptyAttributeName !=
                                                          null) {
                                                        // Boş attributeName göndererek handleImageUpload çağrılır
                                                        final String?
                                                            uploadedImageUrl =
                                                            await handleImageUpload(
                                                          context,
                                                          widget.entitiesId,
                                                          widget.recordId,
                                                          emptyAttributeName,
                                                          oldImageValues,
                                                          {}, // Ekstra veriler (optional)
                                                        );

                                                        if (uploadedImageUrl !=
                                                            null) {
                                                          // Image URL yüklendikten sonra oldImageValues güncellenir
                                                          setState(() {
                                                            imageValues[
                                                                    emptyAttributeName!] =
                                                                uploadedImageUrl;
                                                          });

                                                          // fetchRecordData çağrılır
                                                          await _fetchRecordData();
                                                        } else {
                                                          // Hata durumunda yapılacak işlemler
                                                          debugPrint(
                                                              "Image upload failed or canceled.");
                                                        }
                                                      } else {
                                                        // Hiç boş Manual Image yoksa kullanıcıya bilgi ver
                                                        showSnackBar(context,
                                                            "No empty Manual Image available!");
                                                      }
                                                      print(emptyAttributeName);
                                                    },
                                                    child: Container(
                                                      width: 150,
                                                      height: 200,
                                                      margin:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      decoration: BoxDecoration(
                                                        image:
                                                            const DecorationImage(
                                                          image: AssetImage(
                                                              "assets/images/background_1.png"),
                                                          fit: BoxFit
                                                              .cover, // Resmi tamamen kaplamak için
                                                        ),
                                                        color: Colors.white
                                                            .withOpacity(0.4),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                              Icons.add_a_photo,
                                                              size: 40,
                                                              color: AppColors
                                                                  .primaryColor),
                                                          const SizedBox(
                                                              height: 5),
                                                          Text(
                                                            TextConstants
                                                                .addImage,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .displayMedium
                                                                ?.copyWith(
                                                                    color: AppColors
                                                                        .primaryColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }

                                                final attribute =
                                                    entity!['groupedAttributes']
                                                            ['Manual Images']
                                                        [index];
                                                final imageUrl = imageValues[
                                                    attribute['name']];

                                                if (imageUrl == null ||
                                                    imageUrl.isEmpty) {
                                                  return Container(); // Boş container, hata vermeyi engeller
                                                }

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Stack(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    Dialog(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            25),
                                                              ),
                                                              child: Stack(
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            25),
                                                                    child: Image.network(
                                                                        imageUrl,
                                                                        fit: BoxFit
                                                                            .contain),
                                                                  ),
                                                                  Positioned(
                                                                    top: 20,
                                                                    right: 20,
                                                                    child:
                                                                        HeaderIcon(
                                                                      icon: Icons
                                                                          .close_rounded,
                                                                      onTap: () =>
                                                                          Navigator.pop(
                                                                              context),
                                                                      iconColor:
                                                                          Colors
                                                                              .white,
                                                                      color: Colors
                                                                          .black38,
                                                                      iconSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                  Positioned(
                                                                      bottom:
                                                                          20,
                                                                      right: 20,
                                                                      child: HeaderIcon(
                                                                          icon: Icons.delete,
                                                                          onTap: () {
                                                                            setState(() {
                                                                              oldImageValues[attribute['name']] = imageValues[attribute['name']] = '';
                                                                            });
                                                                            checkImageForChanges(attribute['name'], {
                                                                              attribute['name']: ''
                                                                            });
                                                                            Navigator.pop(context);
                                                                          },
                                                                          iconColor: Colors.white,
                                                                          color: Colors.black38,
                                                                          iconSize: 15)),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child: Image.network(
                                                            imageUrl,
                                                            fit: BoxFit.cover,
                                                            width: 150,
                                                            height: 200,
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 5,
                                                        right: 5,
                                                        child: SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child: HeaderIcon(
                                                            icon: Icons.delete,
                                                            onTap: () {
                                                              setState(() {
                                                                oldImageValues[
                                                                        attribute[
                                                                            'name']] =
                                                                    imageValues[
                                                                        attribute[
                                                                            'name']] = '';
                                                              });
                                                              checkImageForChanges(
                                                                  attribute[
                                                                      'name'],
                                                                  {
                                                                    attribute[
                                                                        'name']: ''
                                                                  });
                                                            },
                                                            iconColor:
                                                                Colors.white,
                                                            color:
                                                                Colors.black38,
                                                            iconSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    // Manual Images için yatay kaydırılabilir fotoğraf listesi
                                  ],
                                  context: context,
                                );
                              } else if (header == 'Manual Images') {
                                return const SizedBox.shrink();
                              } else if (header == 'Online Pulled Listings') {
                                if (isExpandedList.length <
                                    combinedList.length + 1) {
                                  // Liste boyutunu kontrol et ve yeniden oluştur
                                  isExpandedList = List.filled(
                                      combinedList.length + 1, false);
                                }
                                return buildExpandableSection(
                                  title: 'Online Pulled Listings',
                                  isExpanded: isExpanded,
                                  onToggle: () => toggleExpansion(header),
                                  children: combinedList
                                      .asMap()
                                      .entries
                                      .map<Widget>((entry) {
                                    int index = entry.key;
                                    int correctIndex = index == 1
                                        ? 10
                                        : index == 0
                                            ? 1
                                            : index;
                                    Map<String, String> listing = entry.value;
                                    return buildExpandableSection(
                                      title: 'Pulled Listing ${index + 1}',
                                      isExpanded:
                                          index + 1 < isExpandedList.length
                                              ? isExpandedList[index + 1]
                                              : false,
                                      onToggle: () {
                                        setState(() {
                                          if (index + 1 <
                                              isExpandedList.length) {
                                            isExpandedList[index + 1] =
                                                !isExpandedList[index + 1];
                                          }
                                        });
                                      },
                                      children: [
                                        listing['image'] != null &&
                                                listing['image']!.isNotEmpty
                                            ? EntriesImageContainer(
                                                label:
                                                    TextConstants.onlineImage,
                                                imageUrl: listing['image']!,
                                                onTapExport: () {
                                                  setState(() {
                                                    _controllers[
                                                                'Pulled Images']
                                                            ?.text =
                                                        listing['image'] ?? '';
                                                    imageValues[
                                                            'Pulled Images'] =
                                                        listing['image'] ?? '';
                                                  });
                                                })
                                            : const SizedBox.shrink(),
                                        CustomFieldWithoutIcon(
                                          label: TextConstants.msrp,
                                          controller: TextEditingController(
                                              text: listing['msrp']),
                                          onChanged: (value) {
                                            _controllers['MSRP ${correctIndex}']
                                                ?.text = value;
                                          },
                                          onTapExport: () {
                                            setState(() {
                                              _controllers['MSRP']?.text =
                                                  listing['msrp'] ?? '';
                                            });
                                          },
                                        ),
                                        CustomFieldWithoutIcon(
                                          label: TextConstants.title,
                                          controller: TextEditingController(
                                              text: listing['title']),
                                          onChanged: (value) {
                                            _controllers[
                                                    'Title ${correctIndex}']
                                                ?.text = value;
                                          },
                                          onTapExport: () {
                                            setState(() {
                                              _controllers['Title']?.text =
                                                  listing['title'] ?? '';
                                            });
                                          },
                                        ),
                                        CustomCenterTitleButton(
                                          title: TextConstants.keepAllData,
                                          icon: Icons.check_circle,
                                          onTap: () {
                                            setState(() {
                                              _controllers['Title']?.text =
                                                  listing['title'] ?? '';
                                              _controllers['MSRP']?.text =
                                                  listing['msrp'] ?? '';
                                              _controllers['Pulled Images']
                                                      ?.text =
                                                  listing['image'] ?? '';
                                              imageValues['Pulled Images'] =
                                                  listing['image'] ?? '';
                                            });
                                          },
                                        ),
                                      ],
                                      context: context,
                                    );
                                  }).toList(),
                                  context: context,
                                );
                              } else {
                                return buildExpandableSection(
                                  title: header,
                                  isExpanded: isExpanded,
                                  onToggle: () => toggleExpansion(header),
                                  children: entity!['groupedAttributes'][header]
                                      .map<Widget>((attribute) {
                                    return AttributeWidgets
                                        .buildAttributeWidget(
                                      context: context,
                                      attribute: attribute,
                                      header: header,
                                      controllers: _controllers,
                                      dynamicBooleans: dynamicBooleans,
                                      imageValues: imageValues,
                                      oldImageValues: oldImageValues,
                                      entitiesId: entity!["_id"],
                                      recordId: widget.recordId,
                                      onChanged: (value) {
                                        setState(() {
                                          dynamicBooleans[attribute['name']] =
                                              value;
                                        });
                                        checkBooleanForChanges(
                                            attribute['name'],
                                            {attribute['name']: value});
                                      },
                                      onDelete: () {
                                        setState(() {
                                          oldImageValues[attribute['name']] =
                                              imageValues[attribute['name']] =
                                                  '';
                                          checkImageForChanges(
                                              attribute['name'],
                                              {attribute['name']: ''});
                                        });
                                      },
                                    );
                                  }).toList(),
                                  context: context,
                                );
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
}
