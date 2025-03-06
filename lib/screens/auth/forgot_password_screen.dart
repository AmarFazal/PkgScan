import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../constants/ui_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/back_icon.dart';
import '../../widgets/custom_fields.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false; // İşlem durumunu takip eden değişken

  void _sendForgotPassword() async {
    setState(() {
      isLoading = true; // İşlem başladığında loader göster
    });

    await _authService.forgotPassword(_emailController.text, context);

    setState(() {
      isLoading = false; // İşlem tamamlandığında loader gizle
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(55),
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background_2.png"),
                fit: BoxFit
                    .cover, // Görseli ekran boyutuna uyacak şekilde ölçekler
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  TextConstants.forgotPassword,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.primaryColor),
                ),
                UIHelper.mediumVerticalGap,
                CustomField(
                  Icons.person_2_outlined,
                  TextConstants.email,
                  _emailController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.emailAddress,
                ),
                UIHelper.mediumVerticalGap,
                isLoading
                    ? const SpinKitThreeBounce(
                        color: AppColors.primaryColor,
                        size: 30.0,
                      ) // Loader gösteriliyor
                    : AuthButton(
                        title: TextConstants.send,
                        onTap: _sendForgotPassword,
                      ),
              ],
            ),
          ),
          const Positioned(
            top: 46,
            left: 26,
            child: BackIcon(
              icon: Icons.arrow_back_ios_new_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
