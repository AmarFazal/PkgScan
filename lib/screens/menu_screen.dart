import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_pkgscan/screens/account_screen.dart';
import 'package:flutter_pkgscan/widgets/manifests_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/auth_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextConstants.menu,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      TextConstants.userNameUpperCase,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                  ],
                )
              ],
            ),
            Container(
              height: 50,
              width: 50,
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/avatar.jpg'),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  ManifestsTile(
                    title: TextConstants.account,
                    icon: Icons.person_rounded,
                    iconSize: 25,
                    onTap: () {
                      Navigator.pushNamed(context, '/accountScreen');
                    },
                    holdDownWorking: false,
                  ),
                  ManifestsTile(
                    title: TextConstants.help,
                    icon: Icons.help_rounded,
                    iconSize: 25,
                    onTap: () {},
                    holdDownWorking: false,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Text(
                      TextConstants.application,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 8.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ManifestsTile(
                    title: TextConstants.maintenance,
                    icon: Icons.engineering_rounded,
                    iconSize: 25,
                    onTap: () {},
                    holdDownWorking: false,
                  ),
                  ManifestsTile(
                    title: TextConstants.serverSettings,
                    icon: Icons.dns_rounded,
                    iconSize: 25,
                    onTap: () {},
                    holdDownWorking: false,
                  ),
                  ManifestsTile(
                    title: TextConstants.license,
                    icon: Icons.local_police_rounded,
                    iconSize: 25,
                    onTap: () {},
                    holdDownWorking: false,
                  ),
                  ManifestsTile(
                    title: TextConstants.version,
                    icon: Icons.code,
                    iconSize: 25,
                    onTap: () {},
                    holdDownWorking: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
