import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF9100EC); // Ana renk
  static const Color secondaryColor = Color(0xFFF2DEFF);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF494949);
  static const Color secondaryTextColor = Color(0xFF828282);

  static const Color successColor = Color(0xFF33C639);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color blue = Color(0xFF0866FF);
  static const Color darkBlue = Color(0xFF0548B6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color bottomNavigationColor = Color(0xFFFFFFFF);
  static const Color google = Color(0xFFEA4335);
  static const Color lightGray = Color(0xFFBDBDBD);
  static const Color darkGray = Color(0xFF1E1E1E);

  // Primary Swatch (MaterialColor)
  static MaterialColor primarySwatch = MaterialColor(
    0xFF9100EC,
    <int, Color>{
      50: Color(0xFFF3E5FF), // Açık ton
      100: Color(0xFFE1BFFF),
      200: Color(0xFFCE99FF),
      300: Color(0xFFBB73FF),
      400: Color(0xFFA653FF),
      500: Color(0xFF9100EC), // Ana renk
      600: Color(0xFF8300D4),
      700: Color(0xFF7300B8),
      800: Color(0xFF64009C),
      900: Color(0xFF4D0075), // Koyu ton
    },
  );
}
