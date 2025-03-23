import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTapSearch;
  final ValueChanged? onChange;
  final VoidCallback onClear;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onTapSearch,
    this.onChange,
    required this.onClear,
    this.focusNode,
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
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                onTapSearch != null ? onTapSearch!() : null;
              }
            },
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
                    onTapSearch != null
                        ? GestureDetector(
                            onTap: onTapSearch,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.search,
                                  color: AppColors.primaryColor),
                            ),
                          )
                        : const SizedBox.shrink(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: controller.text.isNotEmpty
                          ? GestureDetector(
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.close, color: AppColors.primaryColor),
                        ),
                      )
                          : const SizedBox.shrink(),
                    )

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
