import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Import package baru

import 'onboardingpage.dart';
import 'loginpage_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _selectedAccount;
  List<String> _accountOptions = [];
  bool _isLoading = true; // State untuk menunjukkan apakah data sedang dimuat

  // Konstanta untuk IP komputer dan path API
  static const String _computerIp =
      '192.168.1.10'; // Ganti dengan IP komputer Anda
  static const String _apiBasePath =
      'runnotrack_api'; // Ganti dengan nama folder API Anda

  // --- Variabel untuk Dropdown Kustom ---
  final GlobalKey _dropdownKey = GlobalKey();
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _fetchAccountTypes(); // Panggil fungsi untuk mengambil tipe akun saat widget diinisialisasi
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> _fetchAccountTypes() async {
    setState(() {
      _isLoading = true; // Mulai loading
    });

    final String apiUrl =
        'http://$_computerIp/$_apiBasePath/get_account_types.php';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _accountOptions = List<String>.from(responseData['data']);
            // --- PERUBAHAN 1: Hapus baris ini agar defaultnya kosong ---
            // if (_accountOptions.isNotEmpty) {
            //   _selectedAccount = _accountOptions[0];
            // }
            // _selectedAccount tetap null secara default
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to fetch account types: ${responseData['message']}',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching account types: $e')),
      );
      print('Error fetching account types: $e');
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleDropdown,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 8.0,
                width: size.width,
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.0,
                      ),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children:
                          _accountOptions.map((String value) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAccount = value;
                                  _toggleDropdown();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color:
                                        _selectedAccount == value
                                            ? Theme.of(context).primaryColor
                                            : Colors.black,
                                    fontWeight:
                                        _selectedAccount == value
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF03112B),
      body: Stack(
        children: [
          /// BACKGROUND BIRU GRADIENT
          Container(
            width: size.width,
            height: size.height * 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF062B59), Color(0xFF03112B)],
              ),
            ),
          ),

          /// WHITE WAVE SVG
          Positioned(
            top: size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              "assets/images/loginpage.svg",
              width: size.width,
              fit: BoxFit.fill,
            ),
          ),

          /// BACK BUTTON
          Positioned(
            top: 45,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                );
              },
            ),
          ),

          /// LOGO
          Positioned(
            top: size.height * 0.20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SvgPicture.asset(
                  "assets/images/logolengkap.svg",
                  width: size.width * 0.65,
                ),
              ],
            ),
          ),

          /// CONTENT LOGIN
          Positioned(
            top: size.height * 0.55,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                const Center(
                  child: Text(
                    "Selamat Datang",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF03112B),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// DROPDOWN KUSTOM
                SizedBox(
                  height: 52,
                  child: GestureDetector(
                    key: _dropdownKey,
                    onTap: _toggleDropdown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade400),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedAccount ??
                                "Pilih akun untuk Login", // Ini akan menampilkan teks default
                            style: TextStyle(
                              color:
                                  _selectedAccount == null
                                      ? Colors.grey
                                      : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            _isDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                /// BUTTON MASUK
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _selectedAccount == null
                            ? null // Tombol dinonaktifkan jika masih loading atau belum ada pilihan
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => LoginPageUser(
                                        accountType: _selectedAccount!,
                                      ),
                                ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03112B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Masuk",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// FOOTER
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "RunnoTrack v1.0.0",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "© 2026 ODU",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // --- PERUBAHAN 2: LOADING OVERLAY ---
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(
                  0.6,
                ), // Latar belakang agak gelap
                child: Center(
                  child: LoadingAnimationWidget.twistingDots(
                    // Contoh animasi modern
                    leftDotColor: const Color.fromARGB(
                      255,
                      9,
                      111,
                      236,
                    ), // Warna dot kiri
                    rightDotColor: const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ), // Warna dot kanan
                    size: 80, // Ukuran animasi
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
