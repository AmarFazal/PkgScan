import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/constants/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? buttonColor;

  const AuthButton({super.key, required this.title, required this.onTap, this.buttonColor = AppColors.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 47,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
