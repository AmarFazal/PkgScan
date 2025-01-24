import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HeaderIcon extends StatelessWidget {
  final IconData? icon;
  final String? letter;
  final VoidCallback onTap;
  final Color? color;
  final double? iconSize;
  final double? letterSize;

  const HeaderIcon({
    this.icon,
    Key? key,
    required this.onTap,
    this.letter,
    this.color = AppColors.white,
    this.iconSize = 25,
    this.letterSize = 21,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: icon != null
            ? Icon(
                icon,
                color: AppColors.primaryColor,
                size: iconSize,
              )
            : Center(
                child: Text(
                  textAlign: TextAlign.center,
                  letter!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryColor, fontSize: letterSize),
                ),
              ),
      ),
    );
  }
}
