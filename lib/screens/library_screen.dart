import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/screens/create_record_screen.dart';
import 'package:flutter_pkgscan/screens/record_screen.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/attribute_widgets.dart';
import 'package:flutter_pkgscan/widgets/dialogs/libraries_export_sheet.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:flutter_pkgscan/widgets/table_tile.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import '../utils/scroll_listener_helper.dart';
import '../utils/scroll_utils.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_dropdown_tile_single.dart';
import '../widgets/custom_fields.dart';
import '../widgets/dialogs/barcode_search_dialog.dart';
import '../widgets/dialogs/camera_search_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/name_search_dialog.dart';
import '../widgets/entries_checkbox.dart';
import '../widgets/entries_image_container.dart';
import '../widgets/scrape_status_tile.dart';
import '../widgets/screen_loading.dart';

class LibraryScreen extends StatefulWidget {
  final String? manifestId;
  final String pageTitle;
  final String? entitiesId;

  const LibraryScreen(
      {super.key,
      required this.pageTitle,
      required this.manifestId,
      required this.entitiesId});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isVisible = true;
  late ScrollListenerHelper _scrollHelper;
  final EntitiesService _entitiesService = EntitiesService();
  Map<String, dynamic>? entity;
  List allRecords = []; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  bool isDeleting = false;
  Map<String, dynamic> localSettings = {};
  Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {}; // Dinamik boolean değerlerini saklar
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, String> imageValues = {};
  Map<String, dynamic> oldImageValues = {};

  @override
  void initState() {
    super.initState();
    _retrieveEntity();
    _fetchRecords('');
    _scrollHelper = ScrollListenerHelper(
      scrollController: _scrollController,
      onVisibilityChange: (isVisible) {
        setState(() {
          _isVisible = isVisible;
        });
      },
    );
    _scrollHelper.addListener();
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords(String search) async {
    final data = await RecordService().retrieveRecords(
        context, widget.entitiesId ?? 'Somethings went wrong', search);
    setState(() {
      if (data != null && data.isNotEmpty) {
        // Verilerin boş olmadığından emin ol
        allRecords = data[0]['records']; // Eğer veri varsa, devam et
      } else {
        allRecords = [];
      }
      isLoading = false; // Yükleme durumu kapat
    });
  }

  Future<void> _retrieveEntity() async {
    entity = await _entitiesService.retrieveEntities(context, widget.entitiesId);
    if (entity != null) {
      localSettings = entity!['manifest_settings'];
      debugPrint("These are The Fields in Quick Edit ${localSettings['Fields in Quick Edit']}");
    } else {
      showSnackBar(context, 'Failed to retrieve entity.');
    }
  }

  void _scrollToTop() {
    ScrollUtils.scrollToTop(_scrollController, () {
      setState(() {
        _isVisible = true;
      });
    });
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              widget.pageTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ..._buildHeaderIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderIcons() {
    return [
      Row(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isVisible ? 0.0 : 1.0,
            child: Visibility(
              visible: !_isVisible,
              child: HeaderIcon(
                icon: Icons.search,
                onTap: _scrollToTop,
              ),
            ),
          ),
          const SizedBox(width: 16),
          HeaderIcon(
            icon: Icons.file_open_rounded,
            onTap: () {
              List<dynamic> allData =
                  allRecords.map((record) => record['data']).toList();
              List<String> allKeys = allData
                  .where((element) =>
                      element is Map) // Sadece Map türündeki elemanları seç
                  .expand((element) => (element as Map).keys) // Key'leri al
                  .cast<String>() // Türü List<String>'e dönüştür
                  .toSet() // Tekrarlayan key'leri filtrele
                  .toList(); // Listeye çevir

              showLibrariesExportSheet(context, allKeys, allData);

              // searchedManifests = allRecords.where((record) {
              //   final name = manifest["name"]?.toString().toLowerCase() ?? '';
              //   return name.contains(trimmedQuery);
              // }).toList();
            },
          ),
          const SizedBox(width: 16),
          HeaderIcon(
            icon: Icons.settings,
            onTap: () {
              List allData =
                  allRecords.map((record) => record['data']).toList();
              showLibrariesSettingsSheet(
                context,
                TextEditingController(),
                allData[0],
                widget.entitiesId ?? '',
                false,
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget buildBody() {
    return Column(
      children: [
        _buildSearchBar(), // Custom search bar'ı burada çağırıyoruz
        const SizedBox(height: 10),
        _buildContentList(), // ListView'ı burada çağırıyoruz
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isVisible ? 60 : 0,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: CustomSearchBar(
            controller: _searchController,
            onTap: () {
              _fetchRecords(_searchController.text.trim());
            },
            onClear: () {
              _fetchRecords('');
              setState(() {
                _searchController.text = '';
              });
            },
          ), // Search bar widget'ı burada
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (isLoading) {
      return screenLoading(); // Yükleniyor durumu
    }

    // Eğer allRecords boşsa, kullanıcıya mesaj göster
    if (allRecords.isEmpty) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/no_manifests.png',
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
                const SizedBox(height: 15),
                Text(
                  TextConstants.noRecords,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontSize: 20, color: AppColors.textColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: RefreshIndicator(
          onRefresh: () => _fetchRecords(""),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: allRecords.length, // Liste boyutuna göre öğe sayısı
            itemBuilder: (context, index) {
              final record =
                  allRecords[index]; // İlk düzeydeki 'records' listesine erişim
              final data = record['data']; // İlgili 'data' kısmına erişim
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordScreen(
                        index: index,
                        entitiesId: widget.entitiesId ?? 'Something went wrong',
                        isNew: false,
                        recordId: record['_id'],
                      ),
                    ),
                  );
                },
                child: TableTile(
                    title: data['Title'] ?? data['Code'] ?? "No Data",
                    subtitle: data['Scrape Status'] ?? 'No Status',
                    lot: (data['MSRP'] ?? 'MSRP').toString(),
                    scrapeStatus: data['Scrape Status'] ?? 'No Status',
                    image: (data["Pulled Images"]?.isEmpty ?? true)
                        ? 'https://st4.depositphotos.com/14953852/24787/v/450/depositphotos_247872612-stock-illustration-no-image-available-icon-vector.jpg'
                        : data["Pulled Images"],
                    isLoading: isDeleting,
                    onSwipe: () async {
                      RecordService().archiveRecord(
                        context,
                        allRecords[index]['_id'],
                        allRecords[index]['entity_id'],
                        () {
                          _fetchRecords('');
                        },
                      );
                    },
                    quickEditWidget: localSettings.isNotEmpty &&
                            localSettings['Active Quick Edit'] == true
                        ? GestureDetector(
                            onTap: () {
                              showQuickEditDialog(
                                  context,
                                  allRecords[index]['_id'],
                                  widget.entitiesId ?? 'No entities Id');
                            },
                            child: const Icon(
                              Icons.edit,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          )
                        : const SizedBox.shrink()),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: [
            HeaderIcon(
              onTap: () {},
              icon: Icons.tune,
              color: AppColors.secondaryColor,
            ),
            const Spacer(),
            Text(
              "${allRecords.length} Records",
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 12),
            ),
            const Spacer(),
            HeaderIcon(
              onTap: () async {
                // Text search dialog açılıyor ve kapanması bekleniyor
                await showNameSearchDialog(
                    context, widget.entitiesId ?? 'Something went wrong');

                // Dialog kapandıktan sonra verileri tekrar fetch et
                _fetchRecords('');
              },
              letter: "A",
              letterSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () async {
                // Kamera dialog açılıyor ve kapanması bekleniyor
                await showCameraDialog(
                    context, widget.entitiesId ?? 'Something went wrong');

                // Dialog kapandıktan sonra verileri tekrar fetch et
                _fetchRecords('');
              },
              icon: Icons.remove_red_eye,
              iconSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () async {
                // Barcode arama dialog açılıyor ve kapanması bekleniyor
                await showBarcodeSearchDialog(
                    context, widget.entitiesId ?? 'Something went wrong');

                // Dialog kapandıktan sonra verileri tekrar fetch et
                _fetchRecords('');
              },
              icon: CupertinoIcons.barcode,
              iconSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateRecordScreen(
                      entitiesId: widget.entitiesId ?? 'Something went wrong',
                    ),
                  ),
                );
              },
              icon: Icons.add,
              color: AppColors.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: buildAppBar(),
      body: buildBody(),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }










  // Method to handle sending updated data
  void sendUpdatedData(
      String key, Map<String, dynamic> newValue, String entitiesId) {
    RecordService().updateRecord(context, entitiesId, key, newValue, oldValues);
  }

  // Method to check if there are changes
  void checkBooleanForChanges(String key, Map<String, dynamic> newValue,
      String recordId, String entitiesId) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      RecordService().updateRecord(
          context, entitiesId, recordId, newValue, oldBooleanValues);
      setState(() {
        oldBooleanValues[key] = newValue;
      });
    }
  }

  void saveData(String recordId, String entitiesId) {
    // Iterate through all the controllers and collect the updated data
    Map<String, dynamic> updatedData = {};

    _controllers.forEach((key, controller) {
      updatedData[key] =
          controller.text; // Assuming the value is in the controller's text
    });

    // Send the updated data
    sendUpdatedData(recordId, updatedData, entitiesId);
    // Optionally, show a confirmation or success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully!")),
    );
    Navigator.pop(context);
  }

  Future<void> _fetchRecordData(int index) async {
    final data = await RecordService().retrieveRecords(
        context, widget.entitiesId ?? 'Somethings went wrong', '');
    final record = data[0]['records'][index];
    setState(() {
      if (data != null) {
        allRecords = record;

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
      }
      isLoading = false;
    });
  }

  void showQuickEditDialog(
    BuildContext context,
    String recordId,
    String entityId,
  ) {
    final fieldsInQuickEdit = entity!['manifest_settings']
            ?['Fields in Quick Edit'] as List<dynamic>? ??
        [];

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, // Klavyeye göre padding
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // Dinamik alanları oluşturma
                ...fieldsInQuickEdit.map<Widget>((field) {
                  //print("Bu Manifestin entity içi ${entity!['groupedAttributes']["Main Information"]}");
                  return entity!['groupedAttributes']
                          .map<Widget>((attribute) {
                            print("Baslangic ${entity!["groupedAttributes"]}");
                      return AttributeWidgets.buildAttributeWidget(
                          attribute: attribute,
                          controllers: _controllers,
                          dynamicBooleans: dynamicBooleans,
                          imageValues: {},
                          oldImageValues: oldImageValues,
                          header: 'Main Information',
                          entitiesId: entityId,
                          recordId: recordId,
                          onChanged: (p3) {},
                          onDelete: () {},
                          context: context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
