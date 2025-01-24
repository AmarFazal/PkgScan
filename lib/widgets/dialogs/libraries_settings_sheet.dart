import 'package:flutter/material.dart';

import '../libraries_settings_sheet.dart';

void showLibrariesSettingsSheet(
  BuildContext context,
  TextEditingController startBidController,
  TextEditingController descriptionLengthController,
  TextEditingController bulletPointsController,
  TextEditingController pulledImagesController,
  bool filterDescription,
  bool descriptionHavePrefixSuffix,
  bool haveDescription,
  bool activeQuickEdit,
  List<String> consignorOptions,
  List<String> shelfOptions,
  List<String> currencyOptions,
  List<String> titleOptions,
  List<String> statusOptions,
  List<String> quickEditOptions,
) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return LibrariesSettingsSheet(
        startBidController: startBidController,
        descriptionLengthController: descriptionLengthController,
        bulletPointsController: bulletPointsController,
        pulledImagesController: pulledImagesController,
        filterDescription: filterDescription,
        descriptionHavePrefixSuffix: descriptionHavePrefixSuffix,
        haveDescription: haveDescription,
        activeQuickEdit: activeQuickEdit,
        consignorOptions: consignorOptions,
        shelfOptions: shelfOptions,
        currencyOptions: currencyOptions,
        titleOptions: titleOptions,
        statusOptions: statusOptions,
        quickEditOptions: quickEditOptions,
      );
    },
  );
}
