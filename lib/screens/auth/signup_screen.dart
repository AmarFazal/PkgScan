import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/widgets/auth_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../constants/app_colors.dart';
import '../../constants/text_constants.dart';
import '../../constants/ui_helper.dart';
import '../../services/auth_service.dart';
import '../../widgets/back_icon.dart';
import '../../widgets/custom_fields.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  Future<void> signup() async {
    setState(() {
      isLoading = true;
    });
    try {
      final message = await _authService.signup(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
                          color: AppColors.primaryColor,
                          size: 30.0,
                        )
                      : AuthButton(
                          title: TextConstants.signUp,
                          onTap: signup,
                        ),
                ],
              ),
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
          TextConstants.register,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.primaryColor),
        ),
        UIHelper.smallVerticalGap,
        Text(TextConstants.createYourNewAccount,
            style: Theme.of(context).textTheme.displayMedium),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        CustomField(Icons.verified_user_outlined, TextConstants.username,
            _nameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name),
        UIHelper.smallVerticalGap,
        CustomField(
            Icons.person_2_outlined, TextConstants.email, _emailController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress),
        UIHelper.smallVerticalGap,
        CustomField(
            Icons.lock_outline, TextConstants.password, _passwordController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.visiblePassword),
      ],
    );
  }
}
