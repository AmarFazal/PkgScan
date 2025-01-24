import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/services/auth_service.dart';
import 'package:flutter_pkgscan/widgets/custom_fields.dart';
import 'package:flutter_pkgscan/widgets/manifests_tile.dart';

import '../constants/app_colors.dart';
import '../constants/text_constants.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const double _avatarRadius = 80.0;
  static const double _innerAvatarRadius = 76.0;
  static const double _padding = 17.0;
  static const double _dividerHorizontalPadding = 75.0;
  static const double _dividerVerticalPadding = 35.0;
  static const double _spacingLarge = 25.0;
  static const double _spacingMedium = 20.0;
  static const double _spacingSmall = 15.0;
  final AuthService _authService = AuthService();
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();

  Future<void> deleteAccount() async {
    Navigator.pop(context);
    setState(() {
      _isLoading = true; // İşlem başladığında loader göster
    });
    try {
      final message = await _authService.deleteAccount(
        userEmail,
        _passwordController.text,
        context,
      );
      setState(() {
        _isLoading = false; // İşlem tamamlandığında loader gizle
      });
      _showSnackbar(message);
      Navigator.pushNamedAndRemoveUntil(context ,'/signupWith', (Route<dynamic> route) => false,);
    } catch (e) {
      setState(() {
        _isLoading = false; // İşlem tamamlandığında loader gizle
      });
      _showSnackbar(e.toString());
      print(e.toString()); // Hata mesajını konsola yazdır
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchName();
    fetchEmail();
  }

  Future<void> fetchName() async {
    try {
      final fetchedName = await _authService.getUserName();
      setState(() {
        userName = fetchedName ??
            'No Name Found'; // Gelen veri null ise varsayılan değer
      });
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
      });
    }
  }

  Future<void> fetchEmail() async {
    try {
      final fetchedEmail = await _authService.getUserEmail();
      setState(() {
        userEmail = fetchedEmail ??
            'No Email Found'; // Gelen veri null ise varsayılan değer
      });
    } catch (e) {
      setState(() {
        userEmail = 'Error fetching email';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        TextConstants.account,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: ListView(
        children: [
          const SizedBox(height: _spacingMedium),
          _buildAvatar(),
          const SizedBox(height: _spacingSmall),
          _buildUserName(),
          const SizedBox(height: _spacingLarge),
          _buildProfileFields(),
          _buildDividersAndTiles(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return const Center(
      child: CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: AppColors.primaryColor,
        child: CircleAvatar(
          radius: _innerAvatarRadius,
          backgroundImage: AssetImage('assets/images/avatar.jpg'),
        ),
      ),
    );
  }

  Widget _buildUserName() {
    return Center(
      child: Text(
        userName,
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }

  Widget _buildProfileFields() {
    final TextEditingController _userNameController =
        TextEditingController(text: userName);
    final TextEditingController _emailController =
        TextEditingController(text: userEmail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(TextConstants.username),
        CustomField(
          Icons.person_outline,
          TextConstants.username,
          _userNameController,
        ),
        const SizedBox(height: _spacingSmall),
        _buildFieldLabel(TextConstants.email),
        _buildTile(
          icon: Icons.email_outlined,
          title: _emailController.text,
          iconColor: AppColors.primaryColor,
          textColor: AppColors.textColor,
          onTap: () {},
        ),
        const SizedBox(height: _spacingSmall),
        _buildFieldLabel(TextConstants.currentPlan),
        _buildTile(
          icon: Icons.currency_exchange_rounded,
          title: 'Pro',
          iconColor: AppColors.primaryColor,
          textColor: AppColors.textColor,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.displaySmall,
    );
  }

  Widget _buildDividersAndTiles() {
    return Column(
      children: [
        _buildDivider(),
        _buildTile(
          icon: Icons.file_present_outlined,
          title: TextConstants.termsOfUse,
          iconColor: AppColors.primaryColor,
          textColor: AppColors.textColor,
          onTap: () {},
        ),
        const SizedBox(height: _spacingSmall),
        _buildTile(
          icon: Icons.privacy_tip_outlined,
          title: TextConstants.privacyPolicy,
          iconColor: AppColors.primaryColor,
          textColor: AppColors.textColor,
          onTap: () {},
        ),
        _buildDivider(),
        _buildTile(
          icon: Icons.password,
          title: TextConstants.changePassword,
          iconColor: AppColors.primaryColor,
          textColor: AppColors.primaryColor,
          onTap: () {
            _authService.forgotPassword(userEmail, context);
          },
        ),
        const SizedBox(height: _spacingSmall),
        _buildTile(
          icon: Icons.logout,
          title: TextConstants.logoutButton,
          iconColor: AppColors.errorColor,
          textColor: AppColors.errorColor,
          onTap: () {
            AuthService().logout(context);
          },
        ),
        _buildDivider(),
        _buildTile(
            icon: Icons.delete_forever_rounded,
            title: TextConstants.deleteYourAccount,
            iconColor: AppColors.errorColor,
            textColor: AppColors.errorColor,
            onTap: () => showModalBottomSheet(
                  isScrollControlled: true,
                  // Modal'ın boyutunu klavyeye göre ayarlamak için
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30)), // Oval köşe
                  ),
                  backgroundColor: Colors.white,
                  // Arka plan rengi
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context)
                            .viewInsets
                            .bottom, // Klavyeye göre padding
                        top: 16.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: SingleChildScrollView(
                        // İçeriği kaydırılabilir hale getirir
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock),
                                prefixIconColor: AppColors.primaryColor,
                                hintText: TextConstants.password,
                                hintStyle:
                                    Theme.of(context).textTheme.displayMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  // Oval kenarlık
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // İptal butonuyla popup'ı kapat
                                  },
                                  child: Text(
                                    TextConstants.cancel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: AppColors.errorColor,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: deleteAccount,
                                  child: Text(
                                    TextConstants.delete,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: AppColors.successColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: _dividerVerticalPadding,
        horizontal: _dividerHorizontalPadding,
      ),
      child: Divider(
        color: AppColors.textColor,
        height: 0,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.secondaryColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
