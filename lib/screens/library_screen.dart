

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
import '../utils/records/record_helpers.dart';
import '../utils/scroll_listener_helper.dart';
import '../utils/scroll_utils.dart';
import '../widgets/dialogs/barcode_search_dialog.dart';
import '../widgets/dialogs/camera_search_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/name_search_dialog.dart';
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

  Future<void> _retrieveEntity() async {
    try {
      final fetchedEntity =
      await _entitiesService.retrieveEntities(context, widget.entitiesId);

      if (fetchedEntity == null) {
        showSnackBar(context, 'Failed to retrieve entity.');
        return;
      }

      setState(() {
        entity = fetchedEntity;
        localSettings = entity!['manifest_settings'] ?? {};
      });

      debugPrint("These are The Fields in Quick Edit ${localSettings['Fields in Quick Edit']}");
    } catch (e) {
      debugPrint("Error retrieving entity: $e");
      showSnackBar(context, 'Error retrieving entity.');
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
              List<dynamic> allData = allRecords
                  .map((record) => record['data'])
                  .where((element) => element is Map) // Sadece Map türündeki elemanları seç
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
            focusNode: focusNode,
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
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final record = allRecords[index];
              final data = record['data'];

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
                  focusNode.unfocus();
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
                 onSwipeRight: localSettings['Active Quick Edit'] == true
                     ?() {
                    print('Swiped Right');
                    showQuickEditDialog(context, record['_id'], widget.entitiesId ?? 'Something went wrong');
                  }
                      : null,
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

                showCameraDialog(
                  context,
                  widget.entitiesId ?? 'Something went wrong',
                  () {
                    setState(() {
                      isAddingRecord =
                          false; // addRecord işlemi tamamlandı, loader kapansın
                    });
                    _fetchRecords('');
                  },
                );

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
                  isAddingRecord = true; // İşlem başladı, loader gözüksün
                });

                bool scanResult = await showBarcodeSearchDialog(
                    context, widget.entitiesId ?? 'Something went wrong');

                setState(() {
                  isAddingRecord =
                      scanResult; // addRecord işlemi tamamlandı, loader kapansın
                });

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

  final RecordService _recordService = RecordService();
  Future<void> _fetchRecordData() async {
    final data = await _recordService.retrieveRecords(
        context, widget.entitiesId ?? 'Something went wrong', '');

    if (data != null && data.isNotEmpty) {
      final record = data[0]['records'][2];
      setState(() {
        allRecords = record;

        // Initialize controllers, boolean values, and image values dynamically
        RecordHelpers.initializeControllers(
            _controllers, oldValues, record['data']);
        RecordHelpers.initializeDynamicBooleans(
            dynamicBooleans, oldBooleanValues, record['data']);
        RecordHelpers.initializeImageValues(imageValues, record['data']);
      });
    }
  }

  void showQuickEditDialog(BuildContext context, String recordId, String entityId) {
    final fieldsInQuickEdit = (entity!['manifest_settings']['Fields in Quick Edit'] as List?)?.cast<String>() ?? [];

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // `fieldsInQuickEdit` içinde bulunan her bir öğeyi `Text` widget olarak ekleyelim
                ...fieldsInQuickEdit.map<Widget>((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      field, // Listedeki elemanları gösteriyoruz
                      style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

}
