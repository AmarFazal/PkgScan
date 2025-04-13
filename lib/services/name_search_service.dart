import 'package:flutter_pkgscan_new/services/record_service.dart';
import 'package:flutter_pkgscan_new/widgets/snack_bar.dart';
import 'package:flutter/material.dart';

class NameSearchService {
  void onTitleSend(BuildContext context, String title, String entityId, String recordRequestId) async {
    // RecordService'den gelen mesajı alıyoruz
    final String? data = await RecordService()
        .addRecord(context, entityId, true, "title", title, false, {}, recordRequestId);

    if (data != null) {
      // Dönen mesajı gösteriyoruz
      showSnackBar(context: context,message:  data);
    }
  }
}
