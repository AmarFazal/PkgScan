import 'package:flutter/material.dart';
import 'package:flutter_pkgscan_new/widgets/manifests_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  String userName = 'Loading...';
  String version = 'Loading...';


  @override
  void initState() {
    _fetchName();
    _getVersion();
    super.initState();
  }

  Future<void> _fetchName() async {
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

  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version; // pubspec.yaml içindeki sürüm
    });
  }

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
                      userName,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                  ],
                )
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/accountScreen');
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(100)),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primaryColor,
                    size: 25,
                  )),
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
                  const SizedBox(height: 20),
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
                    subtitle: version,
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
