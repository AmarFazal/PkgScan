import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/screens/record_screen.dart';
import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/table_tile.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/header_icon.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import '../utils/scroll_listener_helper.dart';
import '../utils/scroll_utils.dart';
import '../widgets/dialogs/barcode_search_dialog.dart';
import '../widgets/dialogs/camera_search_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/text_search_dialog.dart';
import '../widgets/screen_loading.dart';
import '../widgets/snack_bar.dart';

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

  @override
  void initState() {
    super.initState();
    requestStoragePermission(Permission.storage);
    _retrieveEntity();
    _fetchRecords();
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


  Future<void> _fetchRecords() async {
    final data = await RecordService()
        .retrieveRecords(context, widget.entitiesId ?? 'Somethings went wrong');

    setState(() {
      if (data != null && data.isNotEmpty) { // Verilerin boş olmadığından emin ol
        allRecords = data[0]['records']; // Eğer veri varsa, devam et


      } else {
      }
      isLoading = false; // Yükleme durumu kapat
    });
  }

  Future<bool> requestStoragePermission(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt>=30) {
      var re = await Permission.manageExternalStorage.request();
      if (re.isGranted) {
        return true;
      }
      else{
        return false;
      }
    } else {
      if(await permission.isGranted){
        return true;
      }
      else{
        var result = await permission.request();
        if(result.isGranted){
          return true;
        }
        else{
          return false;
        }
      }
    }
  }



  Future<void> exportToExcel(BuildContext context, List records) async {
    if (records.isEmpty) {
      print('No records to export');
      return; // Boş liste olduğu için fonksiyonu sonlandırıyoruz
    }

    final xls.Workbook workbook = xls.Workbook();
    final xls.Worksheet sheet = workbook.worksheets[0];

    // Başlıkları ekleme
    List<String> headers = records.first.keys.toList(); // Bu satır artık hata vermez
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    // Verileri ekleme
    for (int rowIndex = 0; rowIndex < records.length; rowIndex++) {
      var record = records[rowIndex];
      for (int colIndex = 0; colIndex < headers.length; colIndex++) {
        var value = record[headers[colIndex]];

        if (value is String) {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText(value);
        } else if (value is int) {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setNumber(value.toDouble()); // int'i double'a çeviriyoruz
        } else if (value is double) {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setNumber(value);
        } else {
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText('');
        }
      }
    }

    // Dosya kaydetmeden önce izinler kontrol edilmesi gerekebilir
    if (await Permission.storage.request().isGranted) {
      Directory? directory;
      if (Platform.isAndroid) {
        if (Platform.version.contains("11") || Platform.version.contains("12") || Platform.version.contains("13")) {
          // Android 11 ve üzeri: Scoped Storage
          directory = Directory('/storage/emulated/0/Documents');
        } else {
          // Android 10 ve altı
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Eğer dizin yoksa oluştur
      if (directory != null && !(await directory.exists())) {
        await directory.create(recursive: true);
      }

      String path = directory!.path;
      String fileName = 'records.xlsx';
      File file = File('$path/$fileName');

      // Dosyayı kaydetme
      final List<int> bytes = workbook.saveAsStream();
      await file.writeAsBytes(bytes);
      showSnackBar(context, 'Excel file saved to $fileName');
    } else {
      showSnackBar(context, 'Storage permission is not granted');
    }

    // Workbook'u serbest bırakma
    workbook.dispose();
  }


  Future<void> _retrieveEntity() async {
    entity =
        await _entitiesService.retrieveEntities(context, widget.entitiesId);
    if (entity != null) {
      // debugPrint('Entity retrieved: ${entity?['subheaderOrder']}');
      setState(() {}); // Arayüzü güncellemek için
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
              List allData = allRecords.map((record) => record['data']).toList();
              exportToExcel(context, allData);
              // searchedManifests = allRecords.where((record) {
              //   final name = manifest["name"]?.toString().toLowerCase() ?? '';
              //   return name.contains(trimmedQuery);
              // }).toList();
            },
          ),
          const SizedBox(width: 16),
          // HeaderIcon(
          //   icon: Icons.settings,
          //   onTap: () =>
          //       showLibrariesSettingsSheet(context, TextEditingController()),
          // ),
        ],
      ),
    ];
  }

  Widget buildBody() {
    return Column(
      children: [
        _buildSearchBar(), // Custom search bar'ı burada çağırıyoruz
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
            onTap: () {},
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
            final record = allRecords[index]; // İlk düzeydeki 'records' listesine erişim
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
                      _fetchRecords();
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
              onTap: () => showTextSearchDialog(context, widget.entitiesId ?? 'Something went wrong'),
              letter: "A",
              letterSize: 18,
              color: AppColors.secondaryColor,
            ),
            const SizedBox(width: 8),
            HeaderIcon(
              onTap: () => showCameraDialog(context, widget.entitiesId!),
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
                    builder: (context) => RecordScreen(
                      entitiesId: widget.entitiesId ?? 'Something went wrong',
                      isNew: true,
                      recordId: '',
                      index: 1,
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
