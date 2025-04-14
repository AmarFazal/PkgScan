import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/screens/record_screen.dart';
import 'package:flutter_pkgscan_new/services/record_data_service.dart';
import 'package:flutter_pkgscan_new/services/record_service.dart';
import 'package:flutter_pkgscan_new/widgets/attribute_widgets.dart';
import 'package:flutter_pkgscan_new/widgets/dialogs/libraries_export_sheet.dart';
import 'package:flutter_pkgscan_new/widgets/snack_bar.dart';
import 'package:flutter_pkgscan_new/widgets/table_tile.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../widgets/custom_search_bar.dart';
import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/config.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import '../services/socket_service.dart';
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
import '../widgets/record_screen/body_sections/manual_images_section.dart';
import '../widgets/screen_loading.dart';

class LibraryScreen extends StatefulWidget {
  final String? manifestId;
  final String pageTitle;
  final String? entitiesId;
  final bool? isGuestMode;

  const LibraryScreen({
    super.key,
    required this.pageTitle,
    required this.manifestId,
    required this.entitiesId,
    this.isGuestMode,
  });

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
  late RecordDataService _recordDataService;
  Map<String, dynamic>? entity;
  List allRecords = []; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  bool isDeleting = false;
  bool isAddingRecord = false;
  Map<String, dynamic> localSettings = {};
  Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {};
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, String> imageValues = {};
  Map<String, dynamic> oldImageValues = {};
  final RecordService _recordService = RecordService();
  Map<String, bool> isLoadingMap = {};
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  List<String>? fieldsInQuickEditSharedPreferences;
  bool allowLoaderCloseSearched = false;
  List<String> attributeNames = [];
  late IO.Socket socket;
  late String recordRequestId;
  final Set<String> _usedRecordIds = {};

  String _generateUniqueRecordRequestId() {
    final random = Random();
    String id;
    do {
      id = List.generate(10, (_) => random.nextInt(10)).join();
    } while (_usedRecordIds.contains(id));
    return id;
  }

  @override
  void initState() {
    super.initState();
    _recordDataService = RecordDataService(_recordService, _entitiesService);
    _loadData();
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
    connectSocket();
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _searchController.dispose();
    focusNode.dispose();
    socket.dispose(); // veya socket.disconnect();
    super.dispose();
  }

  connectSocket() async {
    socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnectError((err) => print('Connect error: $err'));
    socket.onError((err) => print('Socket error: $err'));
    socket.onConnect((_) async {
      print('✅ Connected to Socket.IO server');
      print("Entity ID: ${widget.entitiesId}");

      // Wait and join room
      socket.emit('join_room', {'room_id': widget.entitiesId});
    });
    socket.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    socket.on('join_room_ack', (data) {
      print('🟢 Join room response: $data');
      if (data['status'] == "success" &&
          data['room_id'] == widget.entitiesId &&
          allRecords != null) {
        setState(() {
          isLoading = false;
        });
      }
    });
    socket.on('record_addition_status', (data) {
      print('📡 Received record_status: $data');

      final record = data['record'];
      final recordRequestId = data['record_request_id'];

      if (record != null && record is Map<String, dynamic>) {
        // Eğer _usedRecordIds içinde varsa, çıkar
        if (_usedRecordIds.contains(recordRequestId)) {
          _usedRecordIds.remove(recordRequestId);
          print('🧹 Removed used record_request_id: $recordRequestId');
          print('Used Record Ids: $_usedRecordIds');
        }
      }
      if (record == null || record['data'] == null) {
        print("⚠️ Hatalı veri yapısı: $data");
        return;
      }
      int insertIndex = allRecords.length;

      // UI'yi güncelle
      if (mounted) {
        setState(() {
          allRecords.insert(insertIndex, record); // Yeni kaydı en üste ekle
        });
      }
    });
  }

  Future<void> _loadData({int? index}) async {
    index != null
        ? await _recordDataService.fetchRecordData(
          context,
          widget.entitiesId!,
          index,
          _controllers,
          oldValues,
          dynamicBooleans,
          oldBooleanValues,
          imageValues,
          combinedList,
        )
        : null;

    entity = await _recordDataService.retrieveEntity(
      context,
      widget.entitiesId!,
      dynamicBooleans,
      imageValues,
    );
    setState(() {
      localSettings = entity!['manifest_settings'] ?? {};
    });
    // 🔄 `groupedAttributes` içindeki **bütün listeleri** dolaş
    entity!["groupedAttributes"].forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          if (item is Map && item.containsKey("name")) {
            attributeNames.add(item["name"]);
          }
        }
      }
    });
  }

  Future<void> _fetchRecords(String search) async {
    final data = await RecordService().retrieveRecords(
      context,
      widget.entitiesId ?? 'Somethings went wrong',
      search,
    );
    setState(() {
      if (data != null && data.isNotEmpty) {
        // Verilerin boş olmadığından emin ol
        allRecords = data[0]['records']; // Eğer veri varsa, devam et
      } else {
        allRecords = [];
      }
      //isLoading = false; // Yükleme durumu kapat
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
              child: HeaderIcon(icon: Icons.search, onTap: _scrollToTop),
            ),
          ),
          const SizedBox(width: 16),
          HeaderIcon(
            icon: Icons.file_open_rounded,
            onTap: () {
              List<dynamic> allData =
                  allRecords
                      .map((record) => record['data'])
                      .where(
                        (element) => element is Map,
                      ) // Sadece Map türündeki elemanları seç
                      .toList();

              List<String> allKeys =
                  attributeNames
                      .where((key) {
                        // 'Image ', 'MSRP ', 'Title ' ile başlamayan key'leri al
                        return !(key.startsWith('Image ') ||
                            key.startsWith('MSRP ') ||
                            key.startsWith('Keep All Data ') ||
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
                () => _loadData(),
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                    color: AppColors.textColor,
                  ),
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
            itemCount: allRecords.length + _usedRecordIds.length,
            // Ekstra öğe ekleme
            itemBuilder: (context, index) {
              // Eğer bu index, allRecords listesinden sonra geliyorsa, loader tile göster
              if (index >= allRecords.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: AppColors.secondaryColor,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
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
                      builder:
                          (context) => RecordScreen(
                            index: index,
                            entitiesId:
                                widget.entitiesId ?? 'Something went wrong',
                            isNew: false,
                            recordId: record['_id'],
                          ),
                    ),
                  );
                  focusNode.unfocus();
                  if (refreshRecords == true) {
                    setState(() {
                      _fetchRecords(''); // İşlem başladı, loader gözüksün
                    });
                  }
                },
                child: TweenAnimationBuilder(
                  tween: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  // Her öğeye gecikme
                  curve: Curves.easeOut,
                  builder: (context, Offset offset, child) {
                    return Transform.translate(
                      offset:
                          offset *
                          MediaQuery.of(
                            context,
                          ).size.width, // Sağdan sola kaydırma
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        // Opacity için ayrı animasyon
                        builder: (context, double opacity, child) {
                          return Opacity(opacity: opacity, child: child);
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
                    image:
                        (data["Pulled Images"]?.isEmpty ?? true)
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
                    onSwipeRight:
                        localSettings['Active Quick Edit'] == true
                            ? () {
                              showQuickEditDialog(
                                context,
                                record['_id'],
                                widget.entitiesId ?? 'Something went wrong',
                                index,
                              );
                            }
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    Future<void> handleIconTap(
      Future<bool?> Function(BuildContext, String, String) dialogFunction,
    ) async {
      final id = _generateUniqueRecordRequestId();
      setState(() {
        _usedRecordIds.add(id);
      });

      final result = await dialogFunction(
        context,
        widget.entitiesId ?? 'Something went wrong',
        id,
      );

      if (result == null || result == false) {
        // Kullanıcı işlem yapmadan kapattı ya da 'false' döndü
        setState(() {
          _usedRecordIds.remove(id);
        });
      }
    }

    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          children: [
            const Spacer(),
            Text(
              "${allRecords.length} Records",
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontSize: 12),
            ),
            const Spacer(),
            HeaderIcon(
              letter: "A",
              letterSize: 18,
              color: AppColors.secondaryColor,
              onTap: () => handleIconTap(showNameSearchDialog),
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              icon: Icons.remove_red_eye,
              iconSize: 18,
              color: AppColors.secondaryColor,
              onTap: () => handleIconTap(showCameraDialog),
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              icon: CupertinoIcons.barcode,
              iconSize: 18,
              color: AppColors.secondaryColor,
              onTap: () => handleIconTap(showBarcodeSearchDialog),
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              icon: Icons.add,
              color: AppColors.secondaryColor,
              onTap: () async {
                final id = _generateUniqueRecordRequestId();
                setState(() {
                  _usedRecordIds.add(id);
                });
                final refreshRecords = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RecordScreen(
                          entitiesId: widget.entitiesId ?? 'Something went wrong',
                          isNew: true,
                          recordRequestId: id,
                        ),
                  ),
                );
                focusNode.unfocus();
                if (refreshRecords == true) {
                  // Kullanıcı işlem yapmadan kapattı ya da 'false' döndü
                  setState(() {
                    _usedRecordIds.remove(id);
                  });
                }
              },
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

  void checkImageForChanges(
    String key,
    Map<String, dynamic> newValue,
    String recordId,
    String entityId,
  ) {
    if (oldImageValues[key] != null && oldImageValues[key] != newValue) {
      _recordService.updateRecord(
        context,
        entityId,
        recordId,
        newValue,
        oldImageValues,
      );
      setState(() {
        oldImageValues[key] = newValue; // Make sure to update oldImageValues
        imageValues[key] = newValue[key]; // Make sure to update oldImageValues
      });
    }
  }

  void checkBooleanForChanges(
    String key,
    Map<String, dynamic> newValue,
    String recordId,
    String entityId,
  ) {
    if (oldBooleanValues[key] != null && oldBooleanValues[key] != newValue) {
      _recordService.updateRecord(
        context,
        entityId,
        recordId,
        newValue,
        oldBooleanValues,
      );
      setState(() {
        oldBooleanValues[key] = newValue;
      });
    }
  }

  //

  void showQuickEditDialog(
    BuildContext context,
    String recordId,
    String entityId,
    int index,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    fieldsInQuickEditSharedPreferences = prefs.getStringList(
      'fieldsInQuickEdit',
    );
    // async ekledim
    final fieldsInQuickEdit =
        entity!['manifest_settings'] != null
            ? (entity!['manifest_settings']['Fields in Quick Edit'] as List?)
                    ?.cast<String>() ??
                []
            : (fieldsInQuickEditSharedPreferences as List?)?.cast<String>() ??
                [];

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        bool isLoading = true;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> loadData() async {
              await _loadData(index: index);
              setState(() {
                isLoading = false;
              });
            }

            loadData();
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 5,
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child:
                    isLoading
                        ? const Center(
                          child: SpinKitCircle(
                            color: AppColors.primaryColor,
                            size: 50.0,
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              ...entity!['subheaderOrder']?.map<Widget>((
                                header,
                              ) {
                                if (header == 'Main Information') {
                                  List filteredAttributes =
                                      entity!['groupedAttributes']['Manual Images']
                                          .where(
                                            (attribute) => fieldsInQuickEdit
                                                .contains(attribute['name']),
                                          )
                                          .toList();
                                  return Column(
                                    children: [
                                      // Main Information için normal attribute'lar
                                      ...entity!['groupedAttributes'][header]
                                          .where(
                                            (attribute) => fieldsInQuickEdit
                                                .contains(attribute['name']),
                                          ) // Filtreleme işlemi
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
                                                      imageValues[attribute['name']] =
                                                          '';
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
                                          })
                                          .toList(),
                                      filteredAttributes.length > 0
                                          ? ManualImagesSection(
                                            entity: entity!,
                                            imageValues: imageValues,
                                            oldImageValues: oldImageValues,
                                            entitiesId: widget.entitiesId!,
                                            recordId: recordId,
                                            isLoadingMap: isLoadingMap,
                                            fetchRecordData: _loadData,
                                            isNew: false,
                                          )
                                          : const SizedBox.shrink(),
                                    ],
                                  );
                                } else if (header == 'Manual Images') {
                                  return const SizedBox.shrink();
                                } else if (header == 'Online Pulled Listings') {
                                  if (isExpandedList.length <
                                      combinedList.length + 1) {
                                    isExpandedList = List.filled(
                                      combinedList.length + 1,
                                      true,
                                    );
                                  }

                                  return Column(
                                    children:
                                        combinedList.asMap().entries.map<
                                          Widget
                                        >((entry) {
                                          int index = entry.key;
                                          int correctIndex =
                                              index == 1
                                                  ? 10
                                                  : index == 0
                                                  ? 1
                                                  : index;
                                          Map<String, String> listing =
                                              entry.value;
                                          if (fieldsInQuickEdit.contains(
                                            'MSRP $correctIndex',
                                          )) {
                                            return buildExpandableSection(
                                              title:
                                                  'Pulled Listing ${index + 1}',
                                              isExpanded:
                                                  index + 1 <
                                                          isExpandedList.length
                                                      ? isExpandedList[index +
                                                          1]
                                                      : false,
                                              onToggle: () {
                                                setState(() {
                                                  if (index + 1 <
                                                      isExpandedList.length) {
                                                    isExpandedList[index + 1] =
                                                        !isExpandedList[index +
                                                            1];
                                                  }
                                                });
                                              },
                                              children: [
                                                if (fieldsInQuickEdit.contains(
                                                      'Image $correctIndex',
                                                    ) &&
                                                    listing['image'] != null &&
                                                    listing['image']!
                                                        .isNotEmpty)
                                                  EntriesImageContainer(
                                                    label:
                                                        TextConstants
                                                            .onlineImage,
                                                    imageUrl: listing['image']!,
                                                    onTapExport: () {
                                                      setState(() {
                                                        if (fieldsInQuickEdit
                                                            .contains(
                                                              'Pulled Images',
                                                            )) {
                                                          _controllers['Pulled Images']
                                                                  ?.text =
                                                              listing['image'] ??
                                                              '';
                                                          imageValues['Pulled Images'] =
                                                              listing['image'] ??
                                                              '';
                                                        }
                                                      });
                                                      showSnackBar(
                                                        context: context,
                                                        message:
                                                            TextConstants
                                                                .pulledImageUpdatedInMainInformation,
                                                      );
                                                    },
                                                  ),

                                                // ✅ MSRP Dinamik Olarak Ayarlandı
                                                if (fieldsInQuickEdit.contains(
                                                  'MSRP $correctIndex',
                                                ))
                                                  CustomFieldWithoutIcon(
                                                    label:
                                                        '${TextConstants.msrp} $correctIndex',
                                                    controller:
                                                        TextEditingController(
                                                          text: listing['msrp'],
                                                        ),
                                                    onChanged: (value) {
                                                      _controllers['MSRP $correctIndex']
                                                          ?.text = value;
                                                    },
                                                    onTapExport: () {
                                                      setState(() {
                                                        if (fieldsInQuickEdit
                                                            .contains('MSRP')) {
                                                          _controllers['MSRP']
                                                                  ?.text =
                                                              listing['msrp'] ??
                                                              '';
                                                        }
                                                      });
                                                      showSnackBar(
                                                        context: context,
                                                        message:
                                                            TextConstants
                                                                .msrpUpdatedInMainInformation,
                                                      );
                                                    },
                                                  ),

                                                // ✅ Title Kontrolü
                                                if (fieldsInQuickEdit.contains(
                                                  'Title $correctIndex',
                                                ))
                                                  CustomFieldWithoutIcon(
                                                    label:
                                                        '${TextConstants.title} $correctIndex',
                                                    controller:
                                                        TextEditingController(
                                                          text:
                                                              listing['title'],
                                                        ),
                                                    onChanged: (value) {
                                                      _controllers['Title $correctIndex']
                                                          ?.text = value;
                                                    },
                                                    onTapExport: () {
                                                      setState(() {
                                                        if (fieldsInQuickEdit
                                                            .contains(
                                                              'Title',
                                                            )) {
                                                          _controllers['Title']
                                                                  ?.text =
                                                              listing['title'] ??
                                                              '';
                                                        }
                                                      });
                                                      showSnackBar(
                                                        context: context,
                                                        message:
                                                            TextConstants
                                                                .titleUpdatedInMainInformation,
                                                      );
                                                    },
                                                  ),

                                                // ✅ Keep All Data Butonu Güncellendi
                                                if (fieldsInQuickEdit.contains(
                                                      'Title $correctIndex',
                                                    ) ||
                                                    fieldsInQuickEdit.contains(
                                                      'MSRP $correctIndex',
                                                    ) ||
                                                    fieldsInQuickEdit.contains(
                                                      'Image $correctIndex',
                                                    ))
                                                  CustomCenterTitleButton(
                                                    title:
                                                        TextConstants
                                                            .keepAllData,
                                                    icon: Icons.check_circle,
                                                    onTap: () {
                                                      setState(() {
                                                        if (fieldsInQuickEdit
                                                            .contains(
                                                              'Title',
                                                            )) {
                                                          _controllers['Title']
                                                                  ?.text =
                                                              listing['title'] ??
                                                              '';
                                                        }
                                                        if (fieldsInQuickEdit
                                                            .contains('MSRP')) {
                                                          _controllers['MSRP']
                                                                  ?.text =
                                                              listing['msrp'] ??
                                                              '';
                                                        }
                                                        if (fieldsInQuickEdit
                                                            .contains(
                                                              'Pulled Images',
                                                            )) {
                                                          _controllers['Pulled Images']
                                                                  ?.text =
                                                              listing['image'] ??
                                                              '';
                                                          imageValues['Pulled Images'] =
                                                              listing['image'] ??
                                                              '';
                                                        }
                                                      });
                                                      showSnackBar(
                                                        context: context,
                                                        message:
                                                            TextConstants
                                                                .dataUpdatedInMainInformation,
                                                      );
                                                    },
                                                  ),
                                              ],
                                              context: context,
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        }).toList(),
                                  );
                                }

                                return const SizedBox();
                              }).toList(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _recordDataService.saveRecordData(
        context: context,
        controllers: _controllers,
        imageValues: imageValues,
        oldValues: oldValues,
        entitiesId: entityId,
        recordId: recordId,
        isNew: false,
        isRecordScreen: false,

      );
      Future.delayed(const Duration(seconds: 2), () {
        _fetchRecords("");
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
