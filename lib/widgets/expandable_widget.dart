import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Widget buildExpandableSection({
  required BuildContext context,
  required String title,
  required bool isExpanded,
  required VoidCallback onToggle,
  required List<Widget> children,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: onToggle, // Başlığa tıklanınca aç/kapa
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: AppColors.textColor),
            ),
            Icon(
              isExpanded
                  ? Icons.arrow_drop_up_rounded
                  : Icons.arrow_drop_down_rounded,
              color: AppColors.textColor,
              size: 35,
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      if (isExpanded) ...children, // Eğer genişletilmişse içerikleri göster
    ],
  );
}