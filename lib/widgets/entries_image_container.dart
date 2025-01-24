import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class EntriesImageContainer extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback? onTap;

  EntriesImageContainer({
    super.key,
    required this.label,
    required this.imageUrl,  this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 0, bottom: 20,),
        padding: const EdgeInsets.only(
          top: 0,
          bottom: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: AppColors.textColor, fontSize: 13),
              ),
            ),
            ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(imageUrl)),
          ],
        ),
      ),
    );
  }
}
