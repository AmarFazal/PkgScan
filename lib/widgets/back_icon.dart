import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class BackIcon extends StatelessWidget {
  final IconData icon;

  const BackIcon({required this.icon, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: const BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 20,),
      ),
    );
  }
}
