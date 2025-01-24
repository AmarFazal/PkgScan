import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/auth_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/back_icon.dart';
import '../../widgets/custom_fields.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  // Flask API'ye POST isteği gönder
  Future<void> login() async {
    setState(() {
      isLoading = true; // İşlem başladığında loader göster
    });
    try {
      final message = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      setState(() {
        isLoading = false; // İşlem tamamlandığında loader gizle
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mainScreen',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        isLoading = false; // İşlem tamamlandığında loader gizle
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      print(e.toString());
    }
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
                fit: BoxFit.cover, // Görseli ekran boyutuna uyacak şekilde ölçekler
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  TextConstants.welcomeBack,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.primaryColor),
                ),
                const SizedBox(height: 7),
                Text(TextConstants.welcomeMessage,
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 30),
                CustomField(
                  Icons.person_2_outlined,
                  TextConstants.email,
                  _emailController,
                ),
                const SizedBox(height: 20),
                CustomField(
                  Icons.lock_outline,
                  TextConstants.password,
                  _passwordController,
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      child: Text(
                        '${TextConstants.forgotPassword}?',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/forgotPasswordScreen');
                      },
                    )
                  ],
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const SpinKitThreeBounce(
                  color: AppColors.primaryColor,
                  size: 30.0,
                ) // Loader gösteriliyor
                    : AuthButton(
                  title: TextConstants.signIn,
                  onTap: login,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/signUpScreen',
                    );
                  },
                  child: Text(
                    TextConstants.dontHaveAccount,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
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
