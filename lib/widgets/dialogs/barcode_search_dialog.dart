import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/constants/text_constants.dart';
import 'package:flutter_pkgscan_new/widgets/snack_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';
import '../../services/barcode_scanner_service.dart';
import 'dart:async';

import '../auth_button.dart';
import '../custom_fields.dart';

Future<bool?> showBarcodeSearchDialog(
    BuildContext context,
    String entityId,
    String recordRequestId,
    ) async {
  final BarcodeScannerService barcodeScannerService = BarcodeScannerService();
  final Completer<bool> completer = Completer<bool>();
  bool isProcessing = false;
  TextEditingController textController = TextEditingController();
  int selectedOption = 0;

  final result = await showModalBottomSheet<bool>(
    isScrollControlled: true,
    enableDrag: false,    // 👈 kaydırarak kapanmaz
    //isDismissible: false,
    context: context,
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        barcodeScannerService.cameraController.stop();
        Future.delayed(const Duration(milliseconds: 500), () {
          barcodeScannerService.cameraController.start().catchError((error) {
          });
        });
      });


      return StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async {
              barcodeScannerService.cameraController.stop();
              return true;
            },

            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: AppColors.secondaryColor,
                        label: Text(
                          TextConstants.scanBarcode,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: selectedOption == 0
                                ? AppColors.white
                                : AppColors.primaryColor,
                          ),
                        ),
                        selected: selectedOption == 0,
                        onSelected: (_) => setState(() => selectedOption = 0),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: AppColors.secondaryColor,
                        label: Text(
                          TextConstants.enterCode,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: selectedOption == 1
                                ? AppColors.white
                                : AppColors.primaryColor,
                          ),
                        ),
                        selected: selectedOption == 1,
                        onSelected: (_) => setState(() => selectedOption = 1),
                      ),
                    ],
                  ),
                  if (selectedOption == 0)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: MobileScanner(
                        controller: barcodeScannerService.cameraController,
                        onDetect: (BarcodeCapture barcodeCapture) async {
                          if (isProcessing) return;
                          isProcessing = true;
            
                          final List<Barcode> barcodes = barcodeCapture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final String barcode = barcodes[0].rawValue ?? '';
                            if (barcode.isNotEmpty) {
                              Navigator.pop(context, true); // işlem yapıldı
                              barcodeScannerService.cameraController.stop();
                              Future.delayed(Duration.zero, () async {
                                await barcodeScannerService.onBarcodeScanned(
                                  context,
                                  barcode,
                                  entityId,
                                  recordRequestId,
                                );
                                isProcessing = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  if (selectedOption == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          CustomFieldWithoutIcon(
                            label: TextConstants.enterBarcodeCode,
                            controller: textController,
                            textInputType: TextInputType.text,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: AuthButton(
                              title: TextConstants.search,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(color: AppColors.white),
                              buttonHeight: 37,
                              onTap: () async {
                                if (textController.text.isNotEmpty) {
                                  Navigator.pop(context, true); // işlem yapıldı
                                  barcodeScannerService.cameraController.stop();
                                  await barcodeScannerService.onBarcodeScanned(
                                    context,
                                    textController.text,
                                    entityId,
                                    recordRequestId,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    barcodeScannerService.cameraController.stop();
    barcodeScannerService.cameraController.dispose(); // Ekstra güvenlik
  });


  barcodeScannerService.cameraController.stop();

  return result; // kullanıcı işlem yaptıysa true, yapmadıysa null döner
}
