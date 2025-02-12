import 'package:flutter_pkgscan/services/record_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class BarcodeScannerService {
  MobileScannerController cameraController = MobileScannerController();

  // Barcode tarandığında çalışacak fonksiyon
  Future<bool> onBarcodeScanned(
      BuildContext context, String barcode, String entityId) async {

    // `addRecord` tamamlanana kadar bekliyoruz
    await RecordService().addRecord(context, entityId, true, "barcode", barcode);

    // İşlem tamamlandıktan sonra FALSE döndür ki loader kapansın
    return false;
  }
}
