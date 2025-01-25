import 'package:flutter/material.dart';

import '../libraries_settings_sheet.dart';

void showLibrariesSettingsSheet(
  BuildContext context,
  TextEditingController searchController,
  Map<String, dynamic> data,
  String entityId,
  bool isManifest,
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
        searchController: searchController,
        data: data,
        entityId: entityId, isManifest: isManifest,
      );
    },
  );
}
