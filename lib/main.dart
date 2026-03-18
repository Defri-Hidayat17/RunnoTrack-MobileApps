import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemChrome
import 'package:runnotrack/splashscreen.dart'; // Import splashscreen.dart kamu

void main() {
  // Pastikan binding Flutter sudah diinisialisasi sebelum mengatur SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // Atur gaya System UI secara global untuk seluruh aplikasi
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Latar belakang status bar putih
      statusBarIconBrightness:
          Brightness.dark, // Ikon status bar hitam (untuk Android)
      statusBarBrightness:
          Brightness.light, // Teks status bar hitam (untuk iOS)
      // Jika Anda juga ingin mengatur navigation bar (bottom bar)
      // systemNavigationBarColor: Colors.white, // Latar belakang navigation bar putih
      // systemNavigationBarIconBrightness: Brightness.dark, // Ikon navigation bar hitam
    ),
  );

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
      // --- PERUBAHAN DI SINI UNTUK SKALA UI KONSISTEN ---
      builder: (context, child) {
        // Di sini, `context` sudah memiliki `MediaQueryData` default.
        // Kita bisa menggunakannya untuk membuat salinan dengan `textScaleFactor` yang diubah.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!, // `child` di sini adalah widget `home` (SplashScreen)
        );
      },
      // --- AKHIR PERUBAHAN ---
      home: const SplashScreen(),
    );
  }
}
