import 'package:flutter/material.dart';
import 'package:flutter_pkgscan/screens/auth/forgot_password_screen.dart';
import 'package:flutter_pkgscan/screens/auth/signup_screen.dart';
import 'package:flutter_pkgscan/screens/auth/signup_with_screen.dart';
import 'package:flutter_pkgscan/screens/manifests_screen.dart';
import 'package:flutter_pkgscan/screens/menu_screen.dart';
import 'package:flutter_pkgscan/screens/tutorials_screen.dart';
import 'constants/app_colors.dart';
import 'screens/account_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'services/auth_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/guest_mode/manifest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await Hive.initFlutter();
  Hive.registerAdapter(ManifestAdapter());
  await Hive.openBox<Manifest>('manifests');

  // Kullanıcının oturum açma durumunu kontrol ediyoruz.
  final isLoggedIn = await authService.isUserLoggedIn();

  // Kullanıcı giriş yapmışsa token yenileme zamanlayıcısını başlatıyoruz.
  if (isLoggedIn) {
    authService.startTokenRefreshScheduler();
  }

  // Uygulamayı çalıştırıyoruz ve başlangıç rotasını ayarlıyoruz.
  runApp(
    MyApp(
      initialRoute: isLoggedIn ? '/mainScreen' : '/signUpWithScreen',
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
        GlobalKey<ScaffoldMessengerState>();
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          toolbarHeight: 90,
        ),
        primaryColor: AppColors.primaryColor,
        primarySwatch: AppColors.primarySwatch,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primaryColor,
          actionTextColor: AppColors.white,
          elevation: 0,
          closeIconColor: AppColors.white,
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 48,
          ),
          bodyMedium: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
          displayLarge: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          displayMedium: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          displaySmall: TextStyle(
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          labelSmall: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: AppColors.secondaryColor,
          textTheme: ButtonTextTheme.primary,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(30)), // Oval köşe
          ),
          backgroundColor: Colors.white,
        ),
        fontFamily: 'Hanken_Grotesk',
        useMaterial3: false,
      ),
      initialRoute: initialRoute,
      routes: {
        '/forgotPasswordScreen': (context) => ForgotPasswordScreen(),
        '/signInScreen': (context) => const SignInScreen(),
        '/signUpScreen': (context) => const SignUpScreen(),
        '/signUpWithScreen': (context) => const SignupWithScreen(),
        '/accountScreen': (context) => const AccountScreen(),
        '/mainScreen': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const ManifestsScreen(),
    const MenuScreen(),
    const TutorialsScreen(),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),

        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onNavItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
