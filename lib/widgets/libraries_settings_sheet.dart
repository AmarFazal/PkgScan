import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/auth_button.dart';
import 'package:shared_preferences/shared_preferences.dart'; // shared_preferences import edildi
import 'package:flutter_pkgscan/services/entities_service.dart';
import 'package:flutter_pkgscan/widgets/custom_dropdown_tile_single.dart';

import '../constants/text_constants.dart';
import 'custom_dropdown_tile.dart';
import 'custom_fields.dart';
import 'entries_checkbox.dart';

class LibrariesSettingsSheet extends StatefulWidget {
  final TextEditingController searchController;
  final Map<String, dynamic> data;
  final String entityId;
  final bool isManifest;

  const LibrariesSettingsSheet({
    super.key,
    required this.searchController,
    required this.data,
    required this.entityId,
    required this.isManifest ,
  });

  @override
  State<LibrariesSettingsSheet> createState() => _LibrariesSettingsSheetState();
}

class _LibrariesSettingsSheetState extends State<LibrariesSettingsSheet> {
  bool isActiveQuickEditChecked = false;
  final TextEditingController dropdownController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Map<String, dynamic>? retrievedData = {};
  Map<String, dynamic>? entity;
  late bool isLoading = false;



  final List<String> _fieldsInQuickEditOptions =
      List.from(TextConstants.fieldsInQuickEditOptions);
  final List<String> _consignorOptions = TextConstants.consignorOptions;
  final List<String> _shelfOptions = TextConstants.shelfOptions;
  final List<String> _currencyOptions = TextConstants.currencyOptions;
  final List<String> _valuesShowingInTableTileOptions =
      TextConstants.valuesShowingInTableTileOptions;

  late TextEditingController _startBidController = TextEditingController();
  late TextEditingController _descriptionLengthController =
      TextEditingController();
  late TextEditingController _bulletPointsController = TextEditingController();
  late TextEditingController _pulledImageCountController =
      TextEditingController();

  final TextEditingController _consignorOptionsController =
      TextEditingController();
  final TextEditingController _shelfOptionsController = TextEditingController();
  final TextEditingController _currencyOptionsController =
      TextEditingController();
  final TextEditingController _titleOptionsController = TextEditingController();
  final TextEditingController _subtitleOptionsController =
      TextEditingController();
  final TextEditingController _statusOptionsController =
      TextEditingController();
  final TextEditingController _checkedFieldsInQuickEditController =
      TextEditingController();

  bool isDontFilterDescription = false;
  bool isDescriptionHavePrefixSuffix = false;
  bool isHaveDescription = false;

  @override
  void initState() {
    super.initState();
    if (widget.isManifest) {
      _loadDataFromPreferences();
    } else {
      _retrieveEntity();
    }

    _fieldsInQuickEditOptions.addAll(widget.data.keys.toList());
    _consignorOptionsController.text = _consignorOptions[0];
    _shelfOptionsController.text = _shelfOptions[0];
    _currencyOptionsController.text = _currencyOptions[0];
    _titleOptionsController.text = _valuesShowingInTableTileOptions[0];
    _subtitleOptionsController.text = _valuesShowingInTableTileOptions[0];
    _statusOptionsController.text = _valuesShowingInTableTileOptions[0];
  }

  Future<void> _retrieveEntity() async {
    setState(() {
      isLoading = true; // Loading başladı
    });

    try {
      entity = await EntitiesService().retrieveEntities(context, widget.entityId);
      if (entity != null) {
        retrievedData = entity!['manifest_settings'];
        print("Retrieved Data: ${retrievedData}");
        _loadDataFromApi();
      } else {
        debugPrint('Failed to retrieve entity.');
      }
    } catch (e) {
      debugPrint('Error retrieving entity: $e');
    } finally {
      setState(() {
        isLoading = false; // İşlem tamamlandı, loading kapatıldı
      });
    }
  }



  Future<void> _loadDataFromApi() async{
    setState(() {
      _startBidController.text =  retrievedData!['Start Bid'] ?? '';
      _descriptionLengthController.text =retrievedData!['Description Length']?? '';
      _bulletPointsController.text = retrievedData!['Bullet Point'] ?? '';
      _pulledImageCountController.text = retrievedData!['Pulled Images Count'] ?? '';
      isDontFilterDescription = retrievedData!['Filter Description'] ?? false;
      isDescriptionHavePrefixSuffix =
          retrievedData!['Description Have Prefix/Suffix'] ?? false;
      isHaveDescription = retrievedData!['Have a Description'] ?? false;
      _consignorOptionsController.text =
          retrievedData!['Consignor'] ?? _consignorOptions[0];
      _shelfOptionsController.text =
          retrievedData!['Shelf'] ?? _shelfOptions[0];
      _currencyOptionsController.text =
          retrievedData!['Currency'] ?? _currencyOptions[0];
      _titleOptionsController.text =
          retrievedData!['Title'] ?? _valuesShowingInTableTileOptions[0];
      _subtitleOptionsController.text =
          retrievedData!['Status'] ?? _valuesShowingInTableTileOptions[0];
      _statusOptionsController.text =
          retrievedData!['Status'] ?? _valuesShowingInTableTileOptions[0];
      isActiveQuickEditChecked = retrievedData!['Active Quick Edit'] ?? false;
      List<dynamic>? fieldsInQuickEdit = retrievedData!['Fields in Quick Edit'];
      _checkedFieldsInQuickEditController.text = fieldsInQuickEdit?.join(', ') ?? '';
    });
  }


  Future<void> _loadDataFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Eğer veriler kaydedilmişse, kaydedilenleri yükle
    setState(() {
      _startBidController.text = prefs.getString('startBid') ?? '';
      _descriptionLengthController.text =
          prefs.getString('descriptionLength') ?? '';
      _bulletPointsController.text = prefs.getString('bulletPoints') ?? '';
      _pulledImageCountController.text =
          prefs.getString('pulledImageCount') ?? '';
      isDontFilterDescription = prefs.getBool('dontFilterDescription') ?? false;
      isDescriptionHavePrefixSuffix =
          prefs.getBool('descriptionHavePrefixSuffix') ?? false;
      isHaveDescription = prefs.getBool('haveDescription') ?? false;
      _consignorOptionsController.text =
          prefs.getString('consignor') ?? _consignorOptions[0];
      _shelfOptionsController.text =
          prefs.getString('shelf') ?? _shelfOptions[0];
      _currencyOptionsController.text =
          prefs.getString('currency') ?? _currencyOptions[0];
      _titleOptionsController.text =
          prefs.getString('title') ?? _valuesShowingInTableTileOptions[0];
      _subtitleOptionsController.text =
          prefs.getString('subtitle') ?? _valuesShowingInTableTileOptions[0];
      _statusOptionsController.text =
          prefs.getString('status') ?? _valuesShowingInTableTileOptions[0];
      isActiveQuickEditChecked = prefs.getBool('activeQuickEdit') ?? false;

      List<String>? fieldsInQuickEdit =
          prefs.getStringList('fieldsInQuickEdit');
      _checkedFieldsInQuickEditController.text =
          fieldsInQuickEdit?.join(', ') ?? '';
    });
  }

  Future<void> saveDataToPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Verileri SharedPreferences'a kaydediyoruz
    prefs.setString('startBid', _startBidController.text);
    prefs.setString('descriptionLength', _descriptionLengthController.text);
    prefs.setString('bulletPoints', _bulletPointsController.text);
    prefs.setString('pulledImageCount', _pulledImageCountController.text);
    prefs.setBool('dontFilterDescription', isDontFilterDescription);
    prefs.setBool('descriptionHavePrefixSuffix', isDescriptionHavePrefixSuffix);
    prefs.setBool('haveDescription', isHaveDescription);
    prefs.setString('consignor', _consignorOptionsController.text);
    prefs.setString('shelf', _shelfOptionsController.text);
    prefs.setString('currency', _currencyOptionsController.text);
    prefs.setString('title', _titleOptionsController.text);
    prefs.setString('subtitle', _subtitleOptionsController.text);
    prefs.setString('status', _statusOptionsController.text);
    prefs.setBool('activeQuickEdit', isActiveQuickEditChecked);
    prefs.setStringList('fieldsInQuickEdit', _checkedFieldsInQuickEditController.text
            .split(',')
            .map((item) => item.trim())
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
        ),
        child:isLoading? Center(child: CircularProgressIndicator( color: Colors.red,),) : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomFieldWithoutIcon(
                      label: TextConstants.startBid,
                      controller: _startBidController,
                    ),
                    CustomFieldWithoutIcon(
                        label: TextConstants.descriptionLength,
                        controller: _descriptionLengthController),
                    CustomFieldWithoutIcon(
                        label: TextConstants.bulletPoints,
                        controller: _bulletPointsController),
                    CustomFieldWithoutIcon(
                        label: TextConstants.pulledImagesCount,
                        controller: _pulledImageCountController),
                    EntriesCheckbox(
                      isChecked: isDontFilterDescription,
                      label: TextConstants.dontFilterDescription,
                      onChanged: (value) {
                        setState(() {
                          isDontFilterDescription = !isDontFilterDescription;
                        });
                      },
                    ),
                    EntriesCheckbox(
                      isChecked: isDescriptionHavePrefixSuffix,
                      label: TextConstants.descriptionHavePrefixSuffix,
                      onChanged: (value) {
                        setState(() {
                          isDescriptionHavePrefixSuffix =
                              !isDescriptionHavePrefixSuffix;
                        });
                      },
                    ),
                    EntriesCheckbox(
                      isChecked: isHaveDescription,
                      label: TextConstants.haveDescription,
                      onChanged: (value) {
                        setState(() {
                          isHaveDescription = !isHaveDescription;
                        });
                      },
                    ),

                    CustomDropdownTileSingle(
                      title: _consignorOptionsController.text,
                      controller: _consignorOptionsController,
                      options: _consignorOptions,
                      label: TextConstants.consignor,
                    ),
                    CustomDropdownTileSingle(
                      title: _shelfOptionsController.text,
                      controller: _shelfOptionsController,
                      options: _shelfOptions,
                      label: TextConstants.shelf,
                    ),
                    CustomDropdownTileSingle(
                      title: _currencyOptionsController.text,
                      controller: _currencyOptionsController,
                      options: _currencyOptions,
                      label: TextConstants.currency,
                    ),
                    CustomDropdownTileSingle(
                      title: _titleOptionsController.text,
                      controller: _titleOptionsController,
                      options: _valuesShowingInTableTileOptions,
                      label: TextConstants.title,
                    ),
                    CustomDropdownTileSingle(
                      title: _subtitleOptionsController.text,
                      controller: _subtitleOptionsController,
                      options: _valuesShowingInTableTileOptions,
                      label: TextConstants.subtitle,
                    ),
                    CustomDropdownTileSingle(
                      title: _statusOptionsController.text,
                      controller: _statusOptionsController,
                      options: _valuesShowingInTableTileOptions,
                      label: TextConstants.status,
                    ),

                    EntriesCheckbox(
                      isChecked: isActiveQuickEditChecked,
                      label: TextConstants.activeQuickEdit,
                      onChanged: (value) {
                        setState(() {
                          isActiveQuickEditChecked = value;
                        });

                        // Yeni bir field eklendiğinde yukarı kaydır
                        if (value) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          });
                        }
                      },
                    ),
                    // Quick Edit aktif olduğunda yeni field göster
                    if (isActiveQuickEditChecked)
                      CustomDropdownTile(
                        controller: _checkedFieldsInQuickEditController,
                        options: _fieldsInQuickEditOptions,
                        title: TextConstants.fieldsinQuickEdit,
                        placeholder: _checkedFieldsInQuickEditController.text,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AuthButton(
                onTap: () async {
                  Map<String, dynamic> body = {
                    "Start Bid": _startBidController.text,
                    "Description Length": _descriptionLengthController.text,
                    "Bullet Point": _bulletPointsController.text,
                    "Pulled Images Count": _pulledImageCountController.text,
                    "Filter Description": isDontFilterDescription,
                    "Description Have Prefix/Suffix":
                        isDescriptionHavePrefixSuffix,
                    "Have a Description": isHaveDescription,
                    "Consignor": _consignorOptionsController.text,
                    "Shelf": _shelfOptionsController.text,
                    "Currency": _currencyOptionsController.text,
                    "Title": _titleOptionsController.text,
                    "Status": _statusOptionsController.text,
                    "Active Quick Edit": isActiveQuickEditChecked,
                    "Fields in Quick Edit": _checkedFieldsInQuickEditController
                        .text
                        .split(',')
                        .map((item) => item.trim())
                        .toSet()
                        .toList(),
                  };
                  // Verileri kaydetme
                  widget.isManifest
                      ? await saveDataToPreferences()
                      : await EntitiesService()
                          .updateEntities(context, widget.entityId, body);
                  Navigator.pop(context);
                },
                title: 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
