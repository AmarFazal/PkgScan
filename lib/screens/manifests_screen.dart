import 'dart:developer';
import 'dart:io';
import 'package:flutter_pkgscan/services/entities_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pkgscan/services/manifest_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../constants/icon_list.dart';
import '../constants/text_constants.dart';
import '../services/record_service.dart';
import '../utils/scroll_listener_helper.dart';
import '../utils/scroll_utils.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/dialogs/add_manifest_dialog.dart';
import '../widgets/dialogs/libraries_settings_sheet.dart';
import '../widgets/dialogs/manifest_settings_dialog.dart';
import '../widgets/header_icon.dart';
import '../widgets/manifests_tile.dart';
import '../widgets/screen_loading.dart';
import 'library_screen.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

class ManifestsScreen extends StatefulWidget {
  const ManifestsScreen({super.key});

  @override
  State<ManifestsScreen> createState() => _ManifestsScreenState();
}

class _ManifestsScreenState extends State<ManifestsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late ScrollListenerHelper _scrollHelper;
  bool _isVisible = true;
  List<Map<String, dynamic>> manifests = []; // Manifest listesi
  List<Map<String, dynamic>> searchedManifests = []; // Manifest listesi
  bool isLoading = true; // Yüklenme durumu
  FocusNode focusNode = FocusNode();
  List<String> manifestNames = [];
  Map<int, IconData?> selectedIcons = {};
  List<Map<String, dynamic>> allRecords = []; // Manifest listesi
  Map<String, dynamic>? entity;
  final EntitiesService _entitiesService = EntitiesService();

  late Map<String, bool> checkboxStates;

  @override
  void initState() {
    super.initState();
    _scrollHelper = ScrollListenerHelper(
      scrollController: _scrollController,
      onVisibilityChange: (isVisible) {
        setState(() {
          _isVisible = isVisible;
        });
      },
    );
    _scrollHelper.addListener();
    fetchManifestsAndUpdate(); // Veriyi çekip listeyi güncelle

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.unfocus();
    });
  }

  // Manifest verilerini çekip listeyi güncelleme fonksiyonu
  Future<void> fetchManifestsAndUpdate() async {
    final data = await ManifestService().retrieveManifests(context);
    setState(() {
      if (data != null) {
        manifests = data; // Veriyi listeye ekleyin
      }
      isLoading = false; // Yükleme durumu kapat
    });
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _searchController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    ScrollUtils.scrollToTop(_scrollController, () {
      setState(() {
        _isVisible = true;
      });
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              TextConstants.manifests,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Row(
            children: _buildHeaderIcons(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderIcons() {
    return [
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
        icon: Icons.add,
        onTap: () {
          showAddManifestDialog(
            context: context,
            iconList: iconList,
            onAdd: (String name, IconData? icon) async {
              setState(() {
                manifestNames.add(name);
                selectedIcons[manifestNames.length - 1] = icon;
              });
              fetchManifestsAndUpdate();
            },
          );
        },
      ),
      const SizedBox(width: 16),
      HeaderIcon(
          icon: Icons.settings_outlined,
          onTap: () => showLibrariesSettingsSheet(
              context, TextEditingController(), {}, '', true)),
    ];
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildSearchBar(),
              // _buildUserData(),
            ],
          ),
        ),
        _buildContentList(),
      ],
    );
  }

  void _filterManifests(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    setState(() {
      if (trimmedQuery.isEmpty) {
        searchedManifests = manifests;
      } else {
        searchedManifests = manifests.where((manifest) {
          final name = manifest["name"]?.toString().toLowerCase() ?? '';
          return name.contains(trimmedQuery);
        }).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isVisible ? 60 : 0,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: CustomSearchBar(
          controller: _searchController,
          focusNode: focusNode,
          onTap: () => _filterManifests(_searchController.text),
          onChange: (value) => _filterManifests(_searchController.text),
          onClear: () {
            _filterManifests('');
            setState(() {
              _searchController.text = '';
            });
          },
        ),
      ),
    );
  }

  Widget _buildUserData() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_2_outlined,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              TextConstants.userNameUpperCase,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.white),
            ),
          ],
        ),
        Text(
          TextConstants.useableStorage,
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildContentList() {
    if (isLoading) {
      return screenLoading();
    }

    if (manifests.isEmpty) {
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
                  TextConstants.noManifestsAddedYet,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontSize: 20, color: AppColors.textColor),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    showAddManifestDialog(
                      context: context,
                      iconList: iconList,
                      onAdd: (String name, IconData? icon) async {
                        setState(() {
                          manifestNames.add(name);
                          selectedIcons[manifestNames.length - 1] = icon;
                        });
                        fetchManifestsAndUpdate(); // Manifest verilerini getir
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      TextConstants.newManifest,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: AppColors.primaryColor),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: searchedManifests.isNotEmpty
              ? searchedManifests.length
              : manifests.length,
          // Eğer arama varsa searchedManifests, yoksa manifests
          itemBuilder: (context, index) {
            final manifest = searchedManifests.isNotEmpty
                ? searchedManifests[index]
                : manifests[index]; // Arama sonuçları ya da tüm liste
            return ManifestsTile(
              title: manifest['name'] ?? 'Unnamed',
              // İsim gösterimi
              subtitle: manifest['description'] ?? 'No description',
              icon: Icons.task,
              // Varsayılan ikon
              iconSize: 35,
              holdDownWorking: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LibraryScreen(
                      pageTitle: manifest['name'] ?? 'Unnamed',
                      manifestId: manifest['_id'],
                      entitiesId: (manifest['entities'] as List).isNotEmpty
                          ? manifest['entities'][0]
                          : null, // Eğer liste boşsa null döner
                    ),
                  ),
                );
                focusNode.unfocus();
              },
              onLongPress: () {
                showManifestSettingsDialog(
                  context: context,
                  manifestId: manifest['_id'],
                  initialName: manifest['name'] ?? 'Unnamed',
                  initialDescription: manifest['description'] ?? '',
                  onTapSave: () {
                    setState(() {
                      fetchManifestsAndUpdate();
                    });
                  },
                  onTapArchive: () {
                    ManifestService().archiveManifest(
                      context,
                      manifest['_id'],
                      () {
                        fetchManifestsAndUpdate();
                      },
                    );
                  },
                  onTapExport: () {},
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
