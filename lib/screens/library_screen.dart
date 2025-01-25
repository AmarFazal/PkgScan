import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/screens/create_record_screen.dart';
import 'package:flutter_pkgscan/screens/record_screen.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/dialogs/libraries_export_sheet.dart';
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
import '../widgets/dialogs/barcode_search_dialog.dart';
import '../widgets/dialogs/camera_search_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/text_search_dialog.dart';
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
    log("$data");
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
      print(localSettings);
    } else {
      debugPrint('Failed to retrieve entity.');
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
              List allData =
                  allRecords.map((record) => record['data']).toList();
              showLibrariesExportSheet(context, allData[0], allData);
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
              List allData = allRecords.map((record) => record['data']).toList();
              showLibrariesSettingsSheet(
                context,
                TextEditingController(),
                allData[0],
                widget.entitiesId ?? '', false,
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
        SizedBox(height: 10),
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
                image: data["Pulled Images"] ??
                    'https://st4.depositphotos.com/14953852/24787/v/450/depositphotos_247872612-stock-illustration-no-image-available-icon-vector.jpg',
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
              ),
            );
          },
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
              onTap: () => showTextSearchDialog(
                  context, widget.entitiesId ?? 'Something went wrong'),
              letter: "A",
              letterSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () => showCameraDialog(context, widget.entitiesId ?? 'Something went wrong'),
              icon: Icons.remove_red_eye,
              iconSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () => showBarcodeSearchDialog(
                  context, widget.entitiesId ?? 'Something went wrong'),
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
}
