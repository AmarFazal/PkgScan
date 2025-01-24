import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/custom_dropdown_tile_single.dart';

import '../constants/text_constants.dart';
import 'custom_dropdown_tile.dart';
import 'custom_fields.dart';
import 'entries_checkbox.dart';

class LibrariesSettingsSheet extends StatefulWidget {
  final TextEditingController startBidController;
  final TextEditingController descriptionLengthController;
  final TextEditingController bulletPointsController;
  final TextEditingController pulledImagesController;
  final bool filterDescription;
  final bool descriptionHavePrefixSuffix;
  final bool haveDescription;
  late bool activeQuickEdit;
  final List<String> consignorOptions;
  final List<String> shelfOptions;
  final List<String> currencyOptions;
  final List<String> titleOptions;
  final List<String> statusOptions;
  final List<String> quickEditOptions;

  LibrariesSettingsSheet({
    Key? key,
    required this.startBidController,
    required this.descriptionLengthController,
    required this.bulletPointsController,
    required this.pulledImagesController,
    required this.filterDescription,
    required this.descriptionHavePrefixSuffix,
    required this.haveDescription,
    required this.activeQuickEdit,
    required this.consignorOptions,
    required this.shelfOptions,
    required this.currencyOptions,
    required this.titleOptions,
    required this.statusOptions,
    required this.quickEditOptions,
  }) : super(key: key);

  @override
  State<LibrariesSettingsSheet> createState() => _LibrariesSettingsSheetState();
}

class _LibrariesSettingsSheetState extends State<LibrariesSettingsSheet> {
  final ScrollController scrollController = ScrollController();

  // final List<String> _fieldsInQuickEditOptions = TextConstants.fieldsInQuickEditOptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom, // Klavyeye göre padding
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFieldWithoutIcon(
                  label: TextConstants.startBid,
                  controller: widget.startBidController),
              CustomFieldWithoutIcon(
                  label: TextConstants.descriptionLength,
                  controller: widget.descriptionLengthController),
              CustomFieldWithoutIcon(
                  label: TextConstants.bulletPoints,
                  controller: widget.bulletPointsController),
              CustomFieldWithoutIcon(
                  label: TextConstants.pulledImagesCount,
                  controller: widget.pulledImagesController),
              EntriesCheckbox(
                isChecked: widget.filterDescription,
                label: TextConstants.dontFilterDescription,
                onChanged: (value) {},
              ),
              EntriesCheckbox(
                isChecked: widget.descriptionHavePrefixSuffix,
                label: TextConstants.descriptionHavePrefixSuffix,
                onChanged: (value) {},
              ),
              EntriesCheckbox(
                isChecked: widget.haveDescription,
                label: TextConstants.haveDescription,
                onChanged: (value) {},
              ),
              CustomDropdownTileSingle(
                title: TextConstants.consignor,
                controller: TextEditingController(),
                options: widget.consignorOptions,
                label: '',
              ),
              CustomDropdownTileSingle(
                title: TextConstants.shelf,
                controller: TextEditingController(),
                options: widget.shelfOptions,
                label: '',
              ),
              CustomDropdownTileSingle(
                title: TextConstants.currency,
                controller: TextEditingController(),
                options: widget.currencyOptions,
                label: '',
              ),
              CustomDropdownTileSingle(
                title: TextConstants.title,
                controller: TextEditingController(),
                options: widget.titleOptions,
                label: '',
              ),
              CustomDropdownTileSingle(
                title: TextConstants.status,
                controller: TextEditingController(),
                options: widget.statusOptions,
                label: '',
              ),
              EntriesCheckbox(
                isChecked: widget.activeQuickEdit,
                label: TextConstants.activeQuickEdit,
                onChanged: (value) {
                  setState(() {
                    widget.activeQuickEdit = value;
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
              if (widget.activeQuickEdit)
                CustomDropdownTile(
                  controller: TextEditingController(),
                  options: widget.quickEditOptions,
                  title: TextConstants.fieldsinQuickEdit,
                  placeholder: 'Please Choose...',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
