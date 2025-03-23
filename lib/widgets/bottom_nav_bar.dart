import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;

  BottomNavBar({required this.selectedIndex, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return GNav(
      gap: 5,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      tabMargin: EdgeInsets.all(8),
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.bottomNavigationColor,
      color: AppColors.secondaryTextColor,
      tabBackgroundColor: AppColors.secondaryColor,
      activeColor: AppColors.primaryColor,
      textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.primaryColor),
      tabs: [
        GButton(icon: Icons.home_outlined, text: "Home"),
        GButton(icon: Icons.menu, text: "Menu"),
        GButton(icon: Icons.video_collection_outlined, text: "Tutorials"),
      ],
      onTabChange: onTabChange,
    );
  }
}
