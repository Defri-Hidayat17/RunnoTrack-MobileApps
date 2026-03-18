import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:runnotrack/onboardingpage.dart';
import 'package:runnotrack/homepage.dart';
import 'package:runnotrack/loginpage_user.dart'; // Ini tetap diimport, tapi tidak langsung digunakan di sini
import 'package:runnotrack/loginpage.dart'; // <--- PASTIKAN INI DIIMPORT

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

    // --- DEBUGGING PRINTS ---
    print('--- SplashScreen Navigation Check ---');
    print('isLoggedIn: $isLoggedIn');
    print('isOnboarded: $isOnboarded');
    print('-----------------------------------');
    // --- END DEBUGGING PRINTS ---

    if (isLoggedIn) {
      print('Navigating to HomePage (User is logged in)');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      if (isOnboarded) {
        print('Navigating to LoginPage (User is onboarded but not logged in)');
        // >>> PERBAIKAN DI SINI: Navigasi ke LoginPage (pemilihan akun)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ), // <--- UBAH INI
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
            child: Image.asset(
              'assets/images/bgsplashscreen.png',
              fit: BoxFit.cover,
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
