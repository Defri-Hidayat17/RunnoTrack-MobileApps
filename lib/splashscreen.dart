import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:runnotrack/onboardingpage.dart';
import 'package:runnotrack/homepage.dart';
import 'package:runnotrack/loginpage_user.dart'; // Ini mungkin tidak lagi diperlukan jika loginpage.dart sudah cukup
import 'package:runnotrack/loginpage.dart';
import 'package:runnotrack/admin_main_scaffold.dart'; // <--- IMPORT INI UNTUK ADMIN

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  static const String _prefsKeyIsLoggedIn = 'is_logged_in';
  static const String _prefsKeyIsOnboarded = 'is_onboarded';
  // Kunci ini diubah dari _prefsKeyAccountType menjadi _prefsKeyRole
  static const String _prefsKeyRole = 'user_role'; // <--- KUNCI BARU UNTUK ROLE

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _checkStatusAndNavigate();
  }

  Future<void> _checkStatusAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(_prefsKeyIsLoggedIn) ?? false;
    final bool isOnboarded = prefs.getBool(_prefsKeyIsOnboarded) ?? false;
    // Mengambil 'role' dari SharedPreferences, bukan 'accountType'
    final String? role = prefs.getString(_prefsKeyRole); // <--- AMBIL ROLE

    // --- DEBUGGING PRINTS ---
    print('--- SplashScreen Navigation Check ---');
    print('isLoggedIn: $isLoggedIn');
    print('isOnboarded: $isOnboarded');
    print('role: $role'); // <--- DEBUGGING ROLE
    print('-----------------------------------');
    // --- END DEBUGGING PRINTS ---

    if (isLoggedIn) {
      // Logika routing sekarang berdasarkan 'role'
      if (role == 'admin') {
        print('Navigating to AdminMainScaffold (Admin role is logged in)');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminMainScaffold()),
        );
      } else if (role == 'operator') {
        // Menggunakan 'operator' sesuai DB Anda
        print('Navigating to HomePage (Operator role is logged in)');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Jika isLoggedIn true tapi role tidak dikenal/null, paksa login ulang
        print(
          'Navigating to LoginPage (Logged in but unknown role, forcing re-login)',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      if (isOnboarded) {
        print('Navigating to LoginPage (User is onboarded but not logged in)');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        print(
          'Navigating to OnboardingPage (User is neither onboarded nor logged in)',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mainLogoWidth = (screenWidth * 0.7).clamp(250.0, 400.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B3C6F),
                        Color(0xFF021E3C),
                        Color(0xFF000F25),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0x220B3C6F),
                        Color(0x33021E3C),
                        Color(0x44000F25),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SvgPicture.asset(
                      'assets/images/logolengkap.svg',
                      width: mainLogoWidth,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
