import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/entities_service.dart';
import '../services/record_data_service.dart';
import '../services/record_service.dart';
import '../widgets/dialogs/save_record_dialog.dart';
import '../widgets/record_screen/body_sections/all_other_sections.dart';
import '../widgets/record_screen/body_sections/main_information_section.dart';
import '../widgets/record_screen/body_sections/manual_images_section.dart';
import '../widgets/record_screen/body_sections/online_pulled_listings_section.dart';

class RecordScreen extends StatefulWidget {
  final String entitiesId;
  final String? recordId;
  final int? index;
  final bool isNew;
  final String? recordRequestId; // only for new records

  const RecordScreen({
    super.key,
    required this.isNew,
    required this.entitiesId,
    this.recordId,
    this.index,
    this.recordRequestId,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool? isChecked = false;
  final EntitiesService _entitiesService = EntitiesService();
  final RecordService _recordService = RecordService();
  late RecordDataService _recordDataService;
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic>? entity;
  Map<String, dynamic>? allRecords;
  bool isLoading = false;
  List<bool> isExpandedList = [];
  List<Map<String, String>> combinedList = [];
  Map<String, dynamic> oldValues = {};
  Map<String, bool> dynamicBooleans = {};
  Map<String, dynamic> oldBooleanValues = {};
  Map<String, String> imageValues = {};
  Map<String, dynamic> oldImageValues = {};
  Map<String, bool> isLoadingMap = {};
  late Map<String, bool> expandedSections = {
    'Main Information': true,
    'Manual Images': true,
    'Online Pulled Listings': true,
    'Other Information': true,
    'Scrape Data': true,
  };

  @override
  void initState() {
    super.initState();
    _recordDataService = RecordDataService(_recordService, _entitiesService);
    _loadData(); // Verileri yüklemek için çağır
  }

  Future<void> _loadData() async {
    widget.isNew == false
        ? allRecords = await _recordDataService.fetchRecordData(
          context,
          widget.entitiesId,
          widget.index,
          _controllers,
          oldValues,
          dynamicBooleans,
          oldBooleanValues,
          imageValues,
          combinedList,
        )
        : allRecords = {};

    entity = await _recordDataService.retrieveEntity(
      context,
      widget.entitiesId,
      dynamicBooleans,
      imageValues,
    );

    setState(() {
      isLoading = false;
    });
  }

  void toggleExpansion(String header) {
    setState(() {
      expandedSections[header] = !expandedSections[header]!;
    });
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    return await showSaveRecordDialog(
          context: context,
          onTapCancel: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onTapSave: () {
            print('OLD VALUES: $oldValues');
            print('Controllers: ${_controllers.values}');

            _recordDataService.saveRecordData(
              context: context,
              controllers: _controllers,
              imageValues: imageValues,
              oldValues: oldValues,
              entitiesId: widget.entitiesId,
              recordId: widget.recordId,
              isNew: widget.isNew,
              isRecordScreen: true,
              recordRequestId: widget.recordRequestId,
            );
            Navigator.of(context).pop(true);
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showUnsavedChangesDialog(context);
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
                child:
                    entity == null || allRecords == null
                        ? const Center(
                          child: SpinKitThreeBounce(
                            color: AppColors.primaryColor,
                            size: 30.0,
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: entity?['subheaderOrder']?.length ?? 0,
                          // Item sayısı
                          itemBuilder: (context, index) {
                            String header =
                                entity!['subheaderOrder'][index]; // Her bir başlık
                            bool isExpanded = expandedSections[header] ?? false;

                            if (header == 'Main Information') {
                              return MainInformationSection(
                                entity: entity!,
                                imageValues: imageValues,
                                oldImageValues: oldImageValues,
                                entitiesId: widget.entitiesId,
                                recordId: widget.recordId,
                                header: header,
                                isExpanded: isExpanded,
                                onToggle: () => toggleExpansion(header),
                                controllers: _controllers,
                                oldBooleanValues: oldBooleanValues,
                                dynamicBooleans: dynamicBooleans,
                                isNew: widget.isNew,
                                manualImage: ManualImagesSection(
                                  entity: entity!,
                                  imageValues: imageValues,
                                  oldImageValues: oldImageValues,
                                  entitiesId: widget.entitiesId,
                                  recordId: widget.recordId,
                                  isLoadingMap: isLoadingMap,
                                  fetchRecordData: _loadData,
                                  isNew: widget.isNew,
                                ),
                              );
                            } else if (header == 'Online Pulled Listings') {
                              if (isExpandedList.length <
                                  combinedList.length + 1) {
                                isExpandedList = List.filled(
                                  combinedList.length + 1,
                                  true,
                                );
                              }
                              return widget.isNew == false
                                  ? OnlinePulledListingsSection(
                                    controllers: _controllers,
                                    imageValues: imageValues,
                                    isExpandedList: isExpandedList,
                                    isExpanded: isExpanded,
                                    combinedList: combinedList,
                                    onToggle: () => toggleExpansion(header),
                                  )
                                  : SizedBox.shrink();
                            } else if (header == 'Manual Images') {
                              return const SizedBox.shrink();
                            } else {
                              return AllOtherSections(
                                entity: entity!,
                                imageValues: imageValues,
                                dynamicBooleans: dynamicBooleans,
                                controllers: _controllers,
                                oldImageValues: oldImageValues,
                                oldBooleanValues: oldBooleanValues,
                                entitiesId: widget.entitiesId,
                                recordId: widget.recordId,
                                header: header,
                                isExpanded: isExpanded,
                                onToggle: () => toggleExpansion(header),
                                isNew: widget.isNew,
                              );
                            }
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
