import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/screens/record_screen.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/attribute_widgets.dart';
import 'package:flutter_pkgscan/widgets/dialogs/libraries_export_sheet.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:flutter_pkgscan/widgets/table_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import '../services/handle_image_upload.dart';
import '../utils/records/record_helpers.dart';
import '../utils/scroll_listener_helper.dart';
import '../utils/scroll_utils.dart';
import '../widgets/custom_center_title_button.dart';
import '../widgets/custom_fields.dart';
import '../widgets/dialogs/barcode_search_dialog.dart';
import '../widgets/dialogs/camera_search_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/name_search_dialog.dart';
import '../widgets/entries_image_container.dart';
import '../widgets/expandable_widget.dart';
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
  FocusNode focusNode = FocusNode();
  bool _isVisible = true;
  late ScrollListenerHelper _scrollHelper;
  final EntitiesService _entitiesService = EntitiesService();
  Map<String, dynamic>? entity;
  List allRecords = []; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  bool isDeleting = false;
  bool isAddingRecord = false;
  Map<String, dynamic> localSettings = {};
  Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {}; // Dinamik boolean değerlerini saklar
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, String> imageValues = {};
  Map<String, dynamic> oldImageValues = {};
  final RecordService _recordService = RecordService();
  Map<String, bool> isLoadingMap = {};
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  List<String>? fieldsInQuickEditSharedPreferences;
  bool allowLoaderCloseSearched = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _searchController.dispose();
    focusNode.dispose();
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
              List<dynamic> allData = allRecords
                  .map((record) => record['data'])
                  .where((element) =>
                      element is Map) // Sadece Map türündeki elemanları seç
                  .toList();

              List<String> allKeys = allData
                  .expand((element) => (element as Map).keys) // Key'leri al
                  .cast<String>() // Türü List<String>'e dönüştür
                  .where((key) {
                    // 'Manual Image', 'Manual MSRP' veya 'Manual Title' ile başlamayan key'leri al
                    return !(key.startsWith('Image ') ||
                        key.startsWith('MSRP ') ||
                        key.startsWith('Title '));
                  })
                  .toSet() // Tekrarlayan key'leri filtrele
                  .toList(); // Listeye çevir

              showLibrariesExportSheet(context, allKeys, allData);
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
                () => _retrieveEntity(),
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
            focusNode: focusNode,
            onTapSearch: () {
              _fetchRecords(_searchController.text);
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
            itemCount: allRecords.length + (isAddingRecord ? 1 : 0),
            // Ekstra öğe ekleme
            itemBuilder: (context, index) {
              if (index == allRecords.length && isAddingRecord) {
                // Listenin en altına indicator ekle
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: AppColors.secondaryColor,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final record = allRecords[index];
              final data = record['data'];

              return GestureDetector(
                onTap: () async {
                  final refreshRecords = await Navigator.push(
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
                  focusNode.unfocus();
                  print(
                      "This is the value that comid from Record Screen: $refreshRecords");
                  if (refreshRecords == true) {
                    setState(() {
                      _fetchRecords(''); // İşlem başladı, loader gözüksün
                    });
                  }
                },
                child: TweenAnimationBuilder(
                  tween: Tween<Offset>(
                      begin: const Offset(1, 0), end: Offset.zero),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  // Her öğeye gecikme
                  curve: Curves.easeOut,
                  builder: (context, Offset offset, child) {
                    return Transform.translate(
                      offset: offset *
                          MediaQuery.of(context)
                              .size
                              .width, // Sağdan sola kaydırma
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        // Opacity için ayrı animasyon
                        builder: (context, double opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: child,
                          );
                        },
                        child: child,
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
                      onSwipeLeft: () async {
                        RecordService().archiveRecord(
                          context,
                          allRecords[index]['_id'],
                          allRecords[index]['entity_id'],
                          () {
                            _fetchRecords('');
                          },
                        );
                      },
                      onSwipeRight: localSettings['Active Quick Edit'] != null
                          ? localSettings['Active Quick Edit'] == true
                              ? () {
                                  print('Swiped Right');
                                  showQuickEditDialog(
                                      context,
                                      record['_id'],
                                      widget.entitiesId ??
                                          'Something went wrong',
                                      index);
                                }
                              : null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              prefs.getBool('activeQuickEdit') == true;
                              print('Swiped Right');
                              showQuickEditDialog(
                                  context,
                                  record['_id'],
                                  widget.entitiesId ?? 'Something went wrong',
                                  index);
                            }),
                ),
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
            // HeaderIcon(
            //   onTap: () {},
            //   icon: Icons.tune,
            //   color: AppColors.secondaryColor,
            // ),
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
                setState(() {
                  isAddingRecord = true;
                });

                // Text search dialog açılıyor ve kapanması bekleniyor
                await showNameSearchDialog(
                    context, widget.entitiesId ?? 'Something went wrong');

                // Dialog kapandıktan sonra verileri tekrar fetch et
                await _fetchRecords('');

                setState(() {
                  isAddingRecord = false;
                });
              },
              letter: "A",
              letterSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () async {
                setState(() {
                  isAddingRecord = true; // İşlem başladı, loader gözüksün
                });

                await showCameraDialog(
                  context,
                  widget.entitiesId ?? 'Something went wrong',
                  () {
                    setState(() {
                      isAddingRecord = false;
                    });
                    _fetchRecords('');
                  },
                  () {
                    allowLoaderCloseSearched = true;
                  },
                );

                if (mounted &&
                    allowLoaderCloseSearched == false &&
                    isAddingRecord == true) {
                  setState(() {
                    isAddingRecord = false;
                    allowLoaderCloseSearched = false;
                  });
                }

                _fetchRecords('');
              },
              icon: Icons.remove_red_eye,
              iconSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () async {
                setState(() {
                  isAddingRecord = true;
                });

                bool scanResult = await showBarcodeSearchDialog(
                  context,
                  widget.entitiesId ?? 'Something went wrong',
                );

                setState(() {
                  isAddingRecord = scanResult;
                  _fetchRecords('');
                });

              },
              icon: CupertinoIcons.barcode,
              iconSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () async {
                final refreshRecords = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordScreen(
                      entitiesId: widget.entitiesId ?? 'Something went wrong',
                      isNew: true,
                    ),
                  ),
                );
                focusNode.unfocus();
                print(
                    "This is the value that comid from Record Screen: $refreshRecords");
                if (refreshRecords == true) {
                  setState(() {
                    _fetchRecords(''); // İşlem başladı, loader gözüksün
                  });
                }
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

  Future<void> _fetchRecordData(int index) async {
    final data = await _recordService.retrieveRecords(
        context, widget.entitiesId ?? 'Something went wrong', '');

    if (data != null && data.isNotEmpty) {
      final record = data[0]['records'][index];
      setState(() {
        // Initialize controllers, boolean values, and image values dynamically
        RecordHelpers.initializeControllers(
            _controllers, oldValues, record['data']);
        RecordHelpers.initializeDynamicBooleans(
            dynamicBooleans, oldBooleanValues, record['data']);
        RecordHelpers.initializeImageValues(imageValues, record['data']);
        print(
            "This is the Record Data That inside _fetchRecordData Function ${record['data']}");
        print("Updated Controllers: $_controllers"); // Ekledim!
        _prepareCombinedList(record['data']);
      });
    }
  }

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

  List<String> _getSortedKeysStartingWith(
      Map<String, dynamic> data, String prefix) {
    return data.keys
        .where((key) => key is String && key.startsWith(prefix))
        .cast<String>()
        .toList()
      ..sort();
  }

  Future<void> _retrieveEntity() async {
    try {
      final fetchedEntity =
          await _entitiesService.retrieveEntities(context, widget.entitiesId);

      if (fetchedEntity == null) {
        showSnackBar(context: context, message: 'Failed to retrieve entity.');
        return;
      }

      setState(() {
        entity = fetchedEntity;
        localSettings = entity!['manifest_settings'] ?? {};
      });

      debugPrint(
          "These are The Fields in Quick Edit ${localSettings['Fields in Quick Edit']}");
    } catch (e) {
      debugPrint("Error retrieving entity: $e");
      showSnackBar(context: context, message: 'Error retrieving entity.');
    }
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

  void checkImageForChanges(
    String key,
    Map<String, dynamic> newValue,
    String recordId,
    String entityId,
  ) {
    if (oldImageValues[key] != null && oldImageValues[key] != newValue) {
      debugPrint(
          "Image New Value: $newValue"); // Ensure image data is updated here
      _recordService.updateRecord(
          context, entityId, recordId, newValue, oldImageValues);
      setState(() {
        oldImageValues[key] = newValue; // Make sure to update oldImageValues
        imageValues[key] = newValue[key]; // Make sure to update oldImageValues
      });
    }
  }

  // Method to check if there are changes
  void checkBooleanForChanges(String key, Map<String, dynamic> newValue,
      String recordId, String entityId) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      debugPrint("Boolean New Value: $newValue");
      _recordService.updateRecord(
          context, entityId, recordId, newValue, oldBooleanValues);
      setState(() {
        oldBooleanValues[key] = newValue;
      });
    }
  }

  void saveData(String recordId, String entitiesId) {
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
    sendUpdatedData(recordId, updatedData, entitiesId);

    // Show a confirmation message and close the screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully!")),
    );
  }

  void sendUpdatedData(
      String key, Map<String, dynamic> newValue, String entitiesId) {
    _recordService.updateRecord(context, entitiesId, key, newValue, oldValues);
  }

  void showQuickEditDialog(
      BuildContext context, String recordId, String entityId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    fieldsInQuickEditSharedPreferences =
        prefs.getStringList('fieldsInQuickEdit');
    // async ekledim
    final fieldsInQuickEdit = entity!['manifest_settings'] != null
        ? (entity!['manifest_settings']['Fields in Quick Edit'] as List?)
                ?.cast<String>() ??
            []
        : (fieldsInQuickEditSharedPreferences as List?)?.cast<String>() ?? [];

    await _fetchRecordData(index); // İşlem bitene kadar bekle

    print("This is the Record Data (AFTER FETCH): ${_controllers}");

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: EdgeInsets.only(
                top: 5,
                left: 16.0,
                right: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    if (entity != null)
                      ...entity!['subheaderOrder']?.map<Widget>((header) {
                        if (header == 'Main Information') {
                          List filteredAttributes = entity!['groupedAttributes']
                                  ['Manual Images']
                              .where((attribute) =>
                                  fieldsInQuickEdit.contains(attribute['name']))
                              .toList();
                          print(
                              "This is the filteredAttributes: ${filteredAttributes.length}");
                          return Column(
                            children: [
                              // Main Information için normal attribute'lar
                              ...entity!['groupedAttributes'][header]
                                  .where((attribute) =>
                                      fieldsInQuickEdit.contains(attribute[
                                          'name'])) // Filtreleme işlemi
                                  .map<Widget>((attribute) {
                                return AttributeWidgets.buildAttributeWidget(
                                  context: context,
                                  attribute: attribute,
                                  header: header,
                                  controllers: _controllers,
                                  dynamicBooleans: dynamicBooleans,
                                  imageValues: imageValues,
                                  oldImageValues: oldImageValues,
                                  entitiesId: entity!["_id"],
                                  recordId: recordId,
                                  onChanged: (value) {
                                    setState(() {
                                      dynamicBooleans[attribute['name']] =
                                          value;
                                    });
                                    checkBooleanForChanges(
                                      attribute['name'],
                                      {attribute['name']: value},
                                      recordId,
                                      entityId,
                                    );
                                  },
                                  onDelete: () {
                                    setState(() {
                                      oldImageValues[attribute['name']] =
                                          imageValues[attribute['name']] = '';
                                      checkImageForChanges(
                                        attribute['name'],
                                        {attribute['name']: ''},
                                        recordId,
                                        entityId,
                                      );
                                    });
                                  },
                                  isNew: false,
                                );
                              }).toList(),
                              filteredAttributes.length > 0
                                  ? Container(
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
                                            height: 200,
                                            // Fotoğrafların yüksekliği
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: entity![
                                                              'groupedAttributes']
                                                          ['Manual Images']
                                                      .where((attribute) =>
                                                          fieldsInQuickEdit
                                                              .contains(
                                                                  attribute[
                                                                      'name']))
                                                      .length +
                                                  1,
                                              // Filtrelenen liste uzunluğu + 1

                                              itemBuilder: (context, index) {
                                                List<String>
                                                    emptyAttributeNames = [];

                                                List filteredAttributes =
                                                    entity!['groupedAttributes']
                                                            ['Manual Images']
                                                        .where((attribute) =>
                                                            fieldsInQuickEdit
                                                                .contains(
                                                                    attribute[
                                                                        'name']))
                                                        .toList();

                                                // Boş attribute'ları kontrol et ve listeyi doldur
                                                for (var attribute
                                                    in filteredAttributes) {
                                                  final attributeName =
                                                      attribute['name'];
                                                  final imageValue =
                                                      imageValues[
                                                          attributeName];
                                                  if ((imageValue == null ||
                                                          imageValue.isEmpty) &&
                                                      attributeName.contains(
                                                          "Manual Image")) {
                                                    emptyAttributeNames
                                                        .add(attributeName);
                                                  }
                                                }

                                                if (index ==
                                                    filteredAttributes.length) {
                                                  // Son eleman, Add Image butonu olacak
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      final List<String>?
                                                          uploadedImageUrls =
                                                          await handleImageUpload(
                                                        context,
                                                        entityId,
                                                        recordId,
                                                        emptyAttributeNames,
                                                        oldImageValues,
                                                        imageValues,
                                                        (attributeName,
                                                            imageUrl) {
                                                          setState(() {
                                                            imageValues[
                                                                    attributeName] =
                                                                imageUrl;
                                                          });
                                                        },
                                                        isLoadingMap,
                                                        false,
                                                      );

                                                      if (uploadedImageUrls !=
                                                          null) {
                                                        await _fetchRecordData(
                                                            index);
                                                      } else {
                                                        showSnackBar(
                                                            context: context,
                                                            message:
                                                                "Image upload failed or canceled. Please Try Again.");
                                                      }
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
                                                          fit: BoxFit.cover,
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
                                                          const SizedBox(
                                                              height: 5),
                                                          Text(
                                                            TextConstants
                                                                    .youHave +
                                                                emptyAttributeNames
                                                                    .length
                                                                    .toString() +
                                                                TextConstants
                                                                    .photosLeft,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .displaySmall
                                                                ?.copyWith(
                                                                    color: AppColors
                                                                        .textColor),
                                                            textAlign: TextAlign
                                                                .center,
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
                                                  return Container();
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
                                                                    bottom: 20,
                                                                    right: 20,
                                                                    child:
                                                                        HeaderIcon(
                                                                      icon: Icons
                                                                          .delete,
                                                                      onTap:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          oldImageValues[attribute['name']] =
                                                                              imageValues[attribute['name']] = '';
                                                                        });
                                                                        checkImageForChanges(
                                                                          attribute[
                                                                              'name'],
                                                                          {
                                                                            attribute['name']:
                                                                                ''
                                                                          },
                                                                          recordId,
                                                                          entityId,
                                                                        );
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      iconColor:
                                                                          Colors
                                                                              .white,
                                                                      color: Colors
                                                                          .black38,
                                                                      iconSize:
                                                                          15,
                                                                    ),
                                                                  ),
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
                                                                },
                                                                recordId,
                                                                entityId,
                                                              );
                                                            },
                                                            iconColor:
                                                                Colors.white,
                                                            color:
                                                                Colors.black38,
                                                            iconSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isLoadingMap[
                                                              attribute[
                                                                  'name']] ==
                                                          true) // Loader göster
                                                        const Positioned.fill(
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(),
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
                                  : SizedBox.shrink()
                              // Manual Images için yatay kaydırılabilir fotoğraf listesi
                            ],
                          );
                        } else if (header == 'Manual Images') {
                          return const SizedBox.shrink();
                        } else if (header == 'Online Pulled Listings') {
                          if (isExpandedList.length < combinedList.length + 1) {
                            // Liste boyutunu kontrol et ve yeniden oluştur
                            isExpandedList =
                                List.filled(combinedList.length + 1, true);
                          }

                          return Column(
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
                              if (fieldsInQuickEdit
                                  .contains('MSRP $correctIndex')) {
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
                                    if (fieldsInQuickEdit
                                            .contains('Image $correctIndex') &&
                                        listing['image'] != null &&
                                        listing['image']!.isNotEmpty)
                                      EntriesImageContainer(
                                        label: TextConstants.onlineImage,
                                        imageUrl: listing['image']!,
                                        onTapExport: () {
                                          setState(() {
                                            if (fieldsInQuickEdit
                                                .contains('Pulled Images')) {
                                              _controllers['Pulled Images']
                                                      ?.text =
                                                  listing['image'] ?? '';
                                              imageValues['Pulled Images'] =
                                                  listing['image'] ?? '';
                                            }
                                          });
                                          showSnackBar(
                                              context: context,
                                              message: TextConstants
                                                  .pulledImageUpdatedInMainInformation);
                                        },
                                      ),

                                    // ✅ MSRP Dinamik Olarak Ayarlandı
                                    if (fieldsInQuickEdit
                                        .contains('MSRP $correctIndex'))
                                      CustomFieldWithoutIcon(
                                        label:
                                            '${TextConstants.msrp} $correctIndex',
                                        controller: TextEditingController(
                                            text: listing['msrp']),
                                        onChanged: (value) {
                                          _controllers['MSRP $correctIndex']
                                              ?.text = value;
                                        },
                                        onTapExport: () {
                                          setState(() {
                                            if (fieldsInQuickEdit
                                                .contains('MSRP')) {
                                              _controllers['MSRP']?.text =
                                                  listing['msrp'] ?? '';
                                            }
                                          });
                                          showSnackBar(
                                              context: context,
                                              message: TextConstants
                                                  .msrpUpdatedInMainInformation);
                                        },
                                      ),

                                    // ✅ Title Kontrolü
                                    if (fieldsInQuickEdit
                                        .contains('Title $correctIndex'))
                                      CustomFieldWithoutIcon(
                                        label:
                                            '${TextConstants.title} $correctIndex',
                                        controller: TextEditingController(
                                            text: listing['title']),
                                        onChanged: (value) {
                                          _controllers['Title $correctIndex']
                                              ?.text = value;
                                        },
                                        onTapExport: () {
                                          setState(() {
                                            if (fieldsInQuickEdit
                                                .contains('Title')) {
                                              _controllers['Title']?.text =
                                                  listing['title'] ?? '';
                                            }
                                          });
                                          showSnackBar(
                                              context: context,
                                              message: TextConstants
                                                  .titleUpdatedInMainInformation);
                                        },
                                      ),

                                    // ✅ Keep All Data Butonu Güncellendi
                                    if (fieldsInQuickEdit
                                            .contains('Title $correctIndex') ||
                                        fieldsInQuickEdit
                                            .contains('MSRP $correctIndex') ||
                                        fieldsInQuickEdit
                                            .contains('Image $correctIndex'))
                                      CustomCenterTitleButton(
                                        title: TextConstants.keepAllData,
                                        icon: Icons.check_circle,
                                        onTap: () {
                                          setState(() {
                                            if (fieldsInQuickEdit
                                                .contains('Title')) {
                                              _controllers['Title']?.text =
                                                  listing['title'] ?? '';
                                            }
                                            if (fieldsInQuickEdit
                                                .contains('MSRP')) {
                                              _controllers['MSRP']?.text =
                                                  listing['msrp'] ?? '';
                                            }
                                            if (fieldsInQuickEdit
                                                .contains('Pulled Images')) {
                                              _controllers['Pulled Images']
                                                      ?.text =
                                                  listing['image'] ?? '';
                                              imageValues['Pulled Images'] =
                                                  listing['image'] ?? '';
                                            }
                                          });
                                          showSnackBar(
                                              context: context,
                                              message: TextConstants
                                                  .dataUpdatedInMainInformation);
                                        },
                                      ),
                                  ],
                                  context: context,
                                );
                              } else {
                                return SizedBox.shrink();
                              }
                            }).toList(),
                          );
                        }

                        return SizedBox();
                      }).toList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).then((_) {
      // Bottom sheet kapandıktan sonra çalışacak kod
      saveData(recordId, entityId);
      Future.delayed(Duration(seconds: 2), () {
        _fetchRecords("");
        print(
            "Bottom sheet kapandı ve 2 saniye sonra fetchRecords çalıştı ve onceki record bilgileri silindi");
        oldImageValues.clear();
        imageValues.clear();
        _controllers.clear();
        oldValues.clear();
        dynamicBooleans.clear();
        oldBooleanValues.clear();
      });
    });
  }
}
