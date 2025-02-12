import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged? onChange;
  final VoidCallback onClear;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onTap,
    this.onChange,
    required this.onClear, this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChange,
            focusNode: focusNode,
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
              suffixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  runAlignment: WrapAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.search, color: AppColors.primaryColor),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClear,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.close, color: AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

            ),
          ),
        ),
      ],
    );
  }
}
