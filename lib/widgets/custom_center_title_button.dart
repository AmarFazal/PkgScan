import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/constants/app_colors.dart';

class CustomCenterTitleButton extends StatelessWidget {
  final Color? backgroundColor;
  final String title;
  final Color? titleColor;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final double? radius;

  const CustomCenterTitleButton({
    super.key,
    this.backgroundColor = AppColors.secondaryColor,
    required this.title,
    this.titleColor = AppColors.successColor,
    this.icon,
    this.iconColor = AppColors.successColor,
    required this.onTap,
    this.radius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.only(top: 0, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius!),
        ),
        child: Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 14,
                    color: titleColor,
                  ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 7),
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ],
          ],
        )),
      ),
    );
  }
}
