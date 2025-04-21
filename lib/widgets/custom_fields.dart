import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/widgets/header_icon.dart';
import '../constants/app_colors.dart';

Widget CustomField(
  IconData icon,
  String hint,
  TextEditingController controller, {
  TextInputAction? textInputAction = TextInputAction.next,
  TextInputType? keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      filled: true,
      fillColor: AppColors.secondaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.primaryColor),
      prefixIcon: Icon(icon, color: AppColors.primaryColor),
    ),
    keyboardType: keyboardType,
    textInputAction: textInputAction,
  );
}

Widget CustomFieldWithoutIcon({
  required String label,
  required TextEditingController? controller,
  ValueChanged? onChanged,
  TextInputType textInputType = TextInputType.multiline,
  int? maxLines = null, // Dinamik satır sayısı (varsayılan olarak sınırsız)
  VoidCallback? onTapExport,
  bool isMsrpEstimated =false,
}) {
  return Container(
    margin: const EdgeInsets.only(top: 0, bottom: 20),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.secondaryColor,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            controller: controller,
            keyboardType: textInputType,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              suffixIcon: isMsrpEstimated ? Icon(Icons.info_outline_rounded,color: AppColors.primaryColor,):SizedBox.shrink()
            ),
          ),
        ),
        onTapExport != null
            ? HeaderIcon(
                color: Colors.white54,
                onTap: onTapExport,
                icon: Icons.upload,
              )
            : const SizedBox.shrink(),
      ],
    ),
  );
}
