import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged? onChange;


  const CustomSearchBar({
    Key? key,
    required this.controller, required this.onTap, this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChange,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintText: TextConstants.search,
        labelStyle: const TextStyle(color: AppColors.primaryColor),
        suffixIcon: GestureDetector(onTap: onTap, child: const Icon(Icons.search, color: AppColors.primaryColor)),
      ),
    );
  }
}
