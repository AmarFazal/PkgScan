import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/constants/text_constants.dart';
import 'package:flutter_pkgscan_new/widgets/snack_bar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';
import '../../services/barcode_scanner_service.dart';
import 'dart:async';

import '../auth_button.dart';
import '../custom_fields.dart';

Future<bool> showBarcodeSearchDialog(
    BuildContext context, String entityId) async {
  final BarcodeScannerService barcodeScannerService = BarcodeScannerService();
  final Completer<bool> completer = Completer<bool>();
  bool isProcessing = false;
  TextEditingController textController = TextEditingController();
  int selectedOption = 0; // 0: Kamera, 1: Manuel giriş
  bool actionTaken = false; // Kullanıcının işlem yapıp yapmadığını takip eder

  await showModalBottomSheet(
    isScrollControlled: true,
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
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
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
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
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
                        actionTaken = true; // İşlem yapıldığını işaretle

                        final List<Barcode> barcodes = barcodeCapture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String barcode = barcodes[0].rawValue ?? '';
                          if (barcode.isNotEmpty) {
                            Navigator.pop(context);
                            Future.delayed(Duration.zero, () async {
                              bool result =
                                  await barcodeScannerService.onBarcodeScanned(
                                context,
                                barcode,
                                entityId,
                              );
                              completer.complete(result);
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
                        horizontal: 16, vertical: 10),
                    child: Column(
                      children: [
                        CustomFieldWithoutIcon(
                          label: TextConstants.enterBarcodeCode,
                          controller: textController,
                          textInputType: TextInputType.number,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          child: AuthButton(
                            title: TextConstants.search,
                            textStyle: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                ),
                            buttonHeight: 37,
                            onTap: () async {
                              if (textController.text.isNotEmpty) {
                                actionTaken = true; // Kullanıcı işlem yaptı
                                Navigator.pop(context);
                                bool result = await barcodeScannerService
                                    .onBarcodeScanned(
                                  context,
                                  textController.text,
                                  entityId,
                                );
                                completer.complete(result);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );

  barcodeScannerService.cameraController.stop();

  // Eğer kullanıcı herhangi bir işlem yapmadan kapattıysa `false` döndür
  if (!actionTaken) {
    completer.complete(false);
  }

  return completer.future;
}
