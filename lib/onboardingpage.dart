import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'dart:async'; // Tidak diperlukan di file ini, hanya di SplashScreen

// Import halaman tujuan navigasi
import 'package:runnotrack/loginpage.dart'; // Import LoginPage yang baru dibuat

// Placeholder untuk HomeScreen. Sebaiknya ini ada di file homescreen.dart
// Jika sudah ada di homescreen.dart, hapus bagian ini dan pastikan importnya benar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: const Center(
        child: Text(
          'Selamat datang di RunnoTrack!',
          style: TextStyle(fontSize: 24, color: Color(0xFF03112B)),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      // Pastikan setState hanya dipanggil jika halaman benar-benar berubah
      if (_pageController.page != null &&
          _currentPage != _pageController.page!.round()) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk membangun dot indikator
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Durasi animasi dot
      margin: const EdgeInsets.symmetric(horizontal: 4.0), // Jarak antar dot
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0, // Dot aktif lebih panjang
      decoration: BoxDecoration(
        color:
            _currentPage == index
                ? const Color(0xFF53B9FF) // Warna dot aktif
                : const Color(
                  0xFFFFFFFF,
                ).withOpacity(0.5), // Warna dot tidak aktif
        borderRadius: BorderRadius.circular(4.0), // Bentuk dot membulat
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF03112B,
      ), // Warna latar belakang halaman onboarding
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: const [
                // Halaman Onboarding 1
                OnboardingContent(
                  imageSvgPath: 'assets/images/onboardingsatu.svg',
                  title: 'Scan QR Instan',
                  description:
                      'Dapatkan data produksi secara instan\ndengan memindai kode QR Hatta',
                ),
                // Halaman Onboarding 2
                OnboardingContent(
                  imageSvgPath: 'assets/images/onboardingdua.svg',
                  title: 'Input Data Cepat & Akurat',
                  description:
                      'Rekam aktivitas produksi dengan mudah\nlangsung dari perangkat seluler Anda.',
                ),
                // Halaman Onboarding 3
                OnboardingContent(
                  imageSvgPath: 'assets/images/onboardingtiga.svg',
                  title: 'Optimalkan Efisiensi',
                  description:
                      'RunnoTrack membantu Anda memantau\ndan mengelola produksi dengan tepat',
                ),
              ],
            ),
          ),
          // Bagian Navigasi Bawah (berbeda untuk halaman terakhir)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child:
                _currentPage <
                        2 // Jika bukan halaman terakhir (0 atau 1)
                    ? Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween, // Menyebar elemen secara horizontal
                      children: [
                        // Tombol "Lewati"
                        TextButton(
                          onPressed: () {
                            // Navigasi langsung ke LoginPage
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Lewati', // Selalu "Lewati" di halaman 0 dan 1
                            style: TextStyle(
                              color: const Color(
                                0xFFFFFFFF,
                              ).withOpacity(0.7), // Warna teks
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500, // Font Inter Medium
                            ),
                          ),
                        ),
                        // Indikator Dot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            _buildDot,
                          ), // Membuat 3 dot indikator
                        ),
                        // Tombol "Lanjut"
                        SizedBox(
                          width: 100.0, // Lebar fixed untuk tombol "Lanjut"
                          height:
                              40.0, // Disesuaikan: Tinggi tombol lebih rendah
                          child: ElevatedButton(
                            onPressed: () {
                              // Pindah ke halaman berikutnya
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeIn,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF53B9FF,
                              ), // Warna tombol Lanjut
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  25.0,
                                ), // Radius membulat
                              ),
                              padding:
                                  EdgeInsets
                                      .zero, // Hapus padding default agar teks pas
                            ),
                            child: const Text(
                              // Teks selalu "Lanjut" di halaman 0 dan 1
                              'Lanjut',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF), // Warna teks tombol
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold, // Font Inter Bold
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : // Jika ini adalah halaman terakhir (_currentPage == 2)
                    SizedBox(
                      width:
                          double
                              .infinity, // Tombol "Mulai" mengambil lebar penuh
                      height: 45.0, // Disesuaikan: Tinggi tombol lebih rendah
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigasi ke LoginPage saat tombol "Mulai" ditekan
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF53B9FF,
                          ), // Warna tombol Mulai
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              25.0,
                            ), // Radius membulat
                          ),
                          padding:
                              EdgeInsets
                                  .zero, // Hapus padding default agar teks pas
                        ),
                        child: const Text(
                          'Mulai', // Teks hanya "Mulai"
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF), // Warna teks tombol
                            fontSize:
                                18.0, // Ukuran font sedikit lebih besar untuk "Mulai"
                            fontWeight: FontWeight.bold, // Font Inter Bold
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk konten setiap halaman onboarding
class OnboardingContent extends StatelessWidget {
  final String imageSvgPath;
  final String title;
  final String description;

  const OnboardingContent({
    super.key,
    required this.imageSvgPath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Elemen SVG (diposisikan di bagian atas, memungkinkan meluap)
        Positioned(
          // Sesuaikan nilai 'top' ini untuk menggeser gambar SVG secara vertikal.
          // Nilai negatif akan mengangkat gambar lebih tinggi.
          // Ini adalah parameter kunci untuk penempatan vertikal SVG agar sesuai desain.
          top:
              MediaQuery.of(context).size.height *
              -0.1, // Disesuaikan: Lebih tinggi dari sebelumnya, tapi tidak setinggi -0.15
          // Sesuaikan 'left' dan 'right' untuk mengontrol seberapa banyak SVG meluap.
          // Nilai negatif akan membuat gambar lebih lebar dari layar.
          left:
              -MediaQuery.of(context).size.width *
              0.2, // Meluap 20% dari lebar layar ke kiri
          right:
              -MediaQuery.of(context).size.width *
              0.2, // Meluap 20% dari lebar layar ke kanan
          child: Center(
            // Memastikan SVG terpusat secara horizontal di dalam batas yang meluap
            child: SvgPicture.asset(
              imageSvgPath,
              // Sesuaikan 'width' dan 'height' untuk ukuran keseluruhan SVG.
              // Ini akan diskalakan secara proporsional.
              width:
                  MediaQuery.of(context).size.width *
                  1.4, // Disesuaikan: Lebih besar dari 1.3
              height:
                  MediaQuery.of(context).size.height *
                  0.55, // Disesuaikan: Lebih besar dari 0.5
              fit: BoxFit.contain, // Mempertahankan rasio aspek SVG
            ),
          ),
        ),

        // Konten Teks (diposisikan di bagian bawah gambar)
        Align(
          alignment:
              Alignment.bottomCenter, // Posisikan teks di bagian bawah layar
          child: Padding(
            // Sesuaikan nilai 'bottom' ini untuk menggeser teks ke atas dari tombol navigasi.
            // Ini adalah parameter kunci untuk penempatan vertikal teks.
            padding: const EdgeInsets.only(
              bottom: 180.0, // Jarak dari bawah layar ke teks
              left: 24.0,
              right: 24.0,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Mengambil ruang vertikal minimum
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF), // Warna teks judul
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold, // Font Inter Bold
                  ),
                ),
                const SizedBox(
                  height: 16.0,
                ), // Jarak antara judul dan deskripsi
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(
                      0xFFFFFFFF,
                    ).withOpacity(0.7), // Warna teks deskripsi
                    fontSize: 15.0,
                    fontWeight: FontWeight.normal, // Font Inter Regular
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
