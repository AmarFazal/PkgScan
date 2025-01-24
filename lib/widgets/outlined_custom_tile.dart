import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OutlinedCustomTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const OutlinedCustomTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
      title: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium,
      ),
      trailing: Icon(
        icon,
        color: AppColors.primaryColor,
      ),
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(
          color: AppColors.lightGray,
        ),
      ),
    );
  }
}
