import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants/app_colors.dart';

Widget screenLoading(){
  return
  Expanded(
    child: Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: const Center(
        child: SpinKitThreeBounce(
          color: AppColors.primaryColor,
          size: 30.0,
        ),
      ),
    ),
  );
}