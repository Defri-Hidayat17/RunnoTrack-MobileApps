import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class HubungiKamiPage extends StatefulWidget {
  const HubungiKamiPage({super.key});

  @override
  State<HubungiKamiPage> createState() => _HubungiKamiPageState();
}

class _HubungiKamiPageState extends State<HubungiKamiPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _klikAnimationController;
  late Animation<double> _klikAnimation;
  bool _showContactOptions = false;

  final String _whatsappNumber = '089509371705'; // Nomor WhatsApp yang diminta
  final String _gmailAddress =
      'defrlugas46@gmail.com'; // Alamat Gmail yang diminta
  final String _appName = 'RunnoTrack'; // Nama aplikasi

  @override
  void initState() {
    super.initState();
    _klikAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Kecepatan animasi pulse
    )..repeat(reverse: true); // Ulangi maju mundur

    _klikAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _klikAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _klikAnimationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    String formattedPhoneNumber =
        _whatsappNumber.startsWith('0')
            ? '62${_whatsappNumber.substring(1)}'
            : _whatsappNumber;
    if (!formattedPhoneNumber.startsWith('62')) {
      formattedPhoneNumber = '62$formattedPhoneNumber';
    }
    final Uri whatsappUrl = Uri.parse('https://wa.me/$formattedPhoneNumber');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      _showSnackBar('Tidak dapat membuka WhatsApp.');
    }
  }

  Future<void> _launchGmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _gmailAddress,
      queryParameters: {
        'subject': 'Pertanyaan dari Aplikasi $_appName', // Subjek email default
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      _showSnackBar('Tidak dapat membuka aplikasi email.');
    }
  }

  // Widget pembantu untuk membuat box opsi kontak yang modern
  Widget _buildContactBox({
    required String iconPath,
    required String label,
    required String appName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.25,
              ), // Lebih gelap untuk efek 3D
              spreadRadius: 3, // Jangkauan bayangan lebih luas
              blurRadius: 18, // Blur lebih besar
              offset: const Offset(
                0,
                10,
              ), // Pergeseran lebih menonjol untuk efek 3D
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconPath, height: 40, width: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF03112B),
                    ),
                  ),
                  Text(
                    'Hubungi melalui $label di $appName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi perkiraan dari Top Bar (padding vertikal 10 + 10 + tinggi icon 30 = 50)
    // Ditambah dengan tinggi status bar (MediaQuery.of(context).padding.top)
    final double topBarHeight = MediaQuery.of(context).padding.top + 50;

    return Scaffold(
      backgroundColor:
          Colors.white, // Background default putih untuk bagian atas
      body: Stack(
        children: [
          // 1. Background Image di bagian bawah (bg_hubkami.svg)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/bg_hubkami.svg',
              height: 400, // Tinggi sudah diatur manual
              width: MediaQuery.of(context).size.width, // Lebar penuh layar
              fit: BoxFit.fill,
            ),
          ),

          // 2. Custom Top Bar (Tombol Kembali & Judul "Hubungi Kami")
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SafeArea(
                bottom: false, // Hanya terapkan padding atas untuk status bar
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Hubungi Kami',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
            ),
          ),

          // 3. Overlay (menggelapkan latar belakang saat opsi kontak muncul)
          if (_showContactOptions)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showContactOptions = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.7)),
              ),
            ),

          // 4. Konten tengah (Admin, Cus, Klik) - POSISI PERSIS SEPERTI SEBELUMNYA, TIDAK TERKENA GELAP
          // Ditempatkan setelah overlay untuk memastikan Z-order yang benar
          Positioned.fill(
            // Menggunakan Positioned.fill untuk mengambil seluruh ruang yang tersedia
            top: topBarHeight, // Dimulai tepat di bawah Top Bar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 30,
                ), // Menambahkan ruang di atas admin untuk menurunkannya
                // Admin Image (diperbesar)
                Image.asset('assets/images/admin.png', height: 180, width: 180),
                const SizedBox(
                  height: 0, // Jarak minimal antara admin dan cus
                ),
                // Customer Service (Cus) dengan Animasi Klik
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showContactOptions = true;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Cus SVG (diperkecil)
                      SvgPicture.asset(
                        'assets/images/cus.svg',
                        height: 60,
                        width: 60,
                      ),
                      // Klik PNG (animasi kedip di kanan cus.svg)
                      Positioned(
                        right: -15, // Posisi horizontal klik
                        top: 25, // Posisi vertikal klik
                        child: ScaleTransition(
                          scale: _klikAnimation,
                          child: Image.asset(
                            'assets/images/klik.png',
                            height: 50,
                            width: 50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Mendorong konten ke atas
              ],
            ),
          ),

          // 5. Box Opsi WhatsApp (Animasi muncul dari bawah)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            right: 20,
            bottom: _showContactOptions ? 100 : -150, // Posisi box WA
            child: _buildContactBox(
              iconPath: 'assets/images/wa.svg',
              label: 'WhatsApp',
              appName: _appName,
              onTap: _launchWhatsApp,
            ),
          ),

          // 6. Box Opsi Gmail (Animasi muncul dari bawah)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            right: 20,
            bottom:
                _showContactOptions
                    ? 10
                    : -150, // Posisi box Gmail (di bawah WA)
            child: _buildContactBox(
              iconPath: 'assets/images/gmail.svg',
              label: 'Gmail',
              appName: _appName,
              onTap: _launchGmail,
            ),
          ),
        ],
      ),
    );
  }
}
