import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/widgets/auth_button.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../services/manifest_service.dart';

Future showSaveRecordDialog({required BuildContext context, required VoidCallback onTapSave, required VoidCallback onTapCancel}) async {
  await showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Manifest ismi için metin alanı
              Text(TextConstants.doYouWantToSaveChanges, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AuthButton(
                      buttonColor: AppColors.errorColor,
                      onTap: onTapCancel,
                      title: TextConstants.cancel,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: AuthButton(
                      buttonColor: AppColors.successColor,
                      onTap: onTapSave,
                      title: TextConstants.save,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
