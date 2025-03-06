import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/auth_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../constants/ui_helper.dart';
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

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final message = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.pushNamedAndRemoveUntil(context, '/mainScreen', (Route<dynamic> route) => false);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  UIHelper.mediumVerticalGap,
                  _buildTextFields(),
                  UIHelper.mediumVerticalGap,
                  isLoading
                      ? const SpinKitThreeBounce(
                          color: AppColors.primaryColor, size: 30.0)
                      : AuthButton(title: TextConstants.signIn, onTap: login),
                  UIHelper.smallVerticalGap,
                  _buildFooter(),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 46,
            left: 26,
            child: BackIcon(icon: Icons.arrow_back_ios_new_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/background_2.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          TextConstants.welcomeBack,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.primaryColor),
        ),
        UIHelper.smallVerticalGap,
        Text(
          TextConstants.welcomeMessage,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        CustomField(
          Icons.person_2_outlined,
          TextConstants.email,
          _emailController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
        ),
        UIHelper.smallVerticalGap,
        CustomField(
          Icons.lock_outline,
          TextConstants.password,
          _passwordController,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/forgotPasswordScreen'),
          child: Text(
            TextConstants.forgotPassword,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        UIHelper.smallHorizontalGap,
        Text(
          TextConstants.or,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        UIHelper.smallHorizontalGap,
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signUpScreen'),
          child: Text(
            TextConstants.createAccount,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
