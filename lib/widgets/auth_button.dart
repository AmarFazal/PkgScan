import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/constants/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? buttonColor;
  final TextStyle? textStyle;
  final double? buttonHeight;

  const AuthButton({
    super.key,
    required this.title,
    required this.onTap,
    this.buttonColor = AppColors.primaryColor,
    this.textStyle, this.buttonHeight = 47,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            title,
            style: textStyle ??
                Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
