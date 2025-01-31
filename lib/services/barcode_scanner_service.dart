import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:flutter_pkgscan/widgets/snack_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class BarcodeScannerService {
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;  // Tarama işleminde olup olmadığını kontrol edecek flag

  // Barcode tarandığında çalışacak fonksiyon
  void onBarcodeScanned(BuildContext context, String barcode, String entityId) async {
    if (isProcessing) return; // Eğer işlem devam ediyorsa, başka işlem yapılmasın
    isProcessing = true; // İşlem başladığında flag'i true yapalım


    // RecordService'den gelen mesajı alıyoruz
    final String? data = await RecordService().addRecord(context, entityId, true, "barcode", barcode);

    if (data != null) {
      // Dönen mesajı gösteriyoruz
      showSnackBar(context, data);
    }

    // Tarama işlemi tamamlandığında, isProcessing flag'ini false yapalım
    // Navigator.pop(context, barcode);
    isProcessing = false;
  }
}
