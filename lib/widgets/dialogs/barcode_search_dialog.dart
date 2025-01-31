import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/barcode_scanner_service.dart';

Future<void> showBarcodeSearchDialog(BuildContext context, String entityId) {
  final BarcodeScannerService barcodeScannerService = BarcodeScannerService();
 return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barcode Scanner widget'ını burada kullanıyoruz
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              // Barcode scanner'ın boyutunu ayarlayabilirsiniz
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
                child: MobileScanner(
                  controller: barcodeScannerService.cameraController,
                  onDetect: (BarcodeCapture barcodeCapture) {
                    // BarcodeCapture objesinden barcode bilgilerine erişiyoruz
                    final List<Barcode> barcodes = barcodeCapture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String barcode =
                          barcodes[0].rawValue ?? ''; // rawValue
                      if (barcode.isNotEmpty) {
                        barcodeScannerService.onBarcodeScanned(
                            context, barcode, entityId); // Barcode tarandığında işleme al
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
