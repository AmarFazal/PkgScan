import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:flutter/material.dart';

class NameSearchService {
  void onTitleSend(BuildContext context, String title, String entityId) async {
    // RecordService'den gelen mesajı alıyoruz
    final String? data = await RecordService()
        .addRecord(context, entityId, true, "title", title);

    if (data != null) {
      // Dönen mesajı gösteriyoruz
      showSnackBar(context, data);
    }
  }
}
