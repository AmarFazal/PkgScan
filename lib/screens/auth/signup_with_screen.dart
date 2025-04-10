import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../widgets/custom_center_title_button.dart';

class SignupWithScreen extends StatefulWidget {
  const SignupWithScreen({super.key});

  @override
  State<SignupWithScreen> createState() => _SignupWithScreenState();
}

class _SignupWithScreenState extends State<SignupWithScreen> {
  @override
  Widget build(BuildContext context) {
    bool isChecked = false;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(55),
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background_1.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TextConstants.bestAppMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCenterTitleButton(
                  title: TextConstants.signIn,
                  titleColor: AppColors.white,
                  backgroundColor: AppColors.primaryColor,
                  radius: 30,
                  onTap: () {
                    Navigator.pushNamed(context, '/signInScreen');
                  },
                ),
                CustomCenterTitleButton(
                  title: TextConstants.signUp,
                  titleColor: AppColors.white,
                  backgroundColor: AppColors.primaryColor,
                  radius: 30,
                  onTap: () {
                    Navigator.pushNamed(context, '/signUpScreen');
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    AuthService().continueAsGuest();
                    Navigator.pushNamedAndRemoveUntil(context, '/mainScreen',
                        (Route<dynamic> route) => false);
                  },
                  child: SizedBox(
                    height: 27,
                    child: Text(
                      TextConstants.continueAsGuest,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() => isChecked = value!);
                      },
                    ),
                    Flexible(
                        child: Text(
                      TextConstants.loremIpsum,
                      style: Theme.of(context).textTheme.displayMedium,
                    ))
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
