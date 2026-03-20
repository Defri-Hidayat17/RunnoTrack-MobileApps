// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemChrome
import 'package:runnotrack/splashscreen.dart'; // Import splashscreen.dart kamu

// --- DEFENISI GAYA GLOBAL DEFAULT UNTUK SELURUH APLIKASI ---
// Ini adalah gaya yang akan diterapkan di sebagian besar halaman dan
// yang akan dipulihkan ketika halaman dengan gaya khusus di-pop.
const SystemUiOverlayStyle
_globalDefaultSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.white, // Status bar default: Putih
  statusBarIconBrightness: Brightness.dark, // Ikon status bar default: Gelap
  statusBarBrightness:
      Brightness.light, // Untuk iOS: Teks gelap di latar terang

  systemNavigationBarColor:
      Colors.white, // Navigation bar default: Putih (PENTING: BUKAN TRANSPARAN)
  systemNavigationBarIconBrightness:
      Brightness.dark, // Ikon navigation bar default: Gelap
  systemNavigationBarDividerColor:
      Colors.transparent, // Opsional: hilangkan garis pemisah jika ada
);

void main() {
  // Pastikan binding Flutter sudah diinisialisasi sebelum mengatur SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Atur gaya System UI secara global untuk seluruh aplikasi
  SystemChrome.setSystemUIOverlayStyle(_globalDefaultSystemUiOverlayStyle);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunnoTrack', // Judul aplikasi
      debugShowCheckedModeBanner: false, // Menghilangkan banner "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF03112B)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
