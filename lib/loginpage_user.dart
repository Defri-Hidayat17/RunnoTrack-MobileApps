import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:math'; // Import for max function
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import 'loginpage.dart';
import 'homepage.dart';

class LoginPageUser extends StatefulWidget {
  final String accountType;

  const LoginPageUser({super.key, required this.accountType});

  @override
  State<LoginPageUser> createState() => _LoginPageUserState();
}

class _LoginPageUserState extends State<LoginPageUser> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FocusNode untuk melacak fokus pada TextField
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Variabel untuk menyimpan posisi bottom dari widget yang sedang fokus
  double _currentFocusedWidgetBottom = 0.0;

  bool _isLoginLoading = false;
  bool _isInitialDataLoading = true;
  bool _obscureText = true;
  bool _rememberMe = false; // State untuk checkbox "Buat saya tetap masuk"

  String? _initialPhotoUrl;

  static const String _computerIp = '192.168.1.10';
  static const String _apiBasePath = 'runnotrack_api';
  // >>> START PERUBAHAN: Tambahkan konstanta kunci Shared Preferences
  static const String _prefsKeyIsLoggedIn = 'is_logged_in';
  // <<< END PERUBAHAN

  // --- Helper untuk InputDecoration agar kode lebih ringkas dan tidak berulang ---
  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF03112B), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRememberMeState(); // Muat status "Buat saya tetap masuk" yang tersimpan
    _fetchInitialAccountPhoto();
    // Tambahkan listener ke FocusNode untuk mendeteksi perubahan fokus
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    // Hapus listener dan dispose FocusNode untuk menghindari memory leak
    _usernameFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Fungsi untuk mendeteksi perubahan fokus dan mendapatkan posisi widget yang fokus
  void _onFocusChange() {
    // Memastikan context masih valid sebelum mencari RenderBox
    if (!mounted) return;

    if (_usernameFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      final RenderBox? renderBox =
          (_usernameFocusNode.hasFocus
                  ? _usernameFocusNode.context?.findRenderObject()
                  : _passwordFocusNode.context?.findRenderObject())
              as RenderBox?;

      if (renderBox != null) {
        // Hitung posisi bottom widget secara global di layar
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _currentFocusedWidgetBottom = offset.dy + renderBox.size.height;
        });
      }
    } else {
      setState(() {
        _currentFocusedWidgetBottom = 0.0; // Reset jika tidak ada yang fokus
      });
    }
  }

  // --- Fungsionalitas "Buat saya tetap masuk" ---
  Future<void> _loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      // Jika kamu ingin menyimpan dan memuat username/password secara otomatis,
      // bisa ditambahkan di sini, misalnya:
      // if (_rememberMe) {
      //   _usernameController.text = prefs.getString('savedUsername') ?? '';
      //   _passwordController.text = prefs.getString('savedPassword') ?? '';
      // }
    });
  }

  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
    // Jika kamu menyimpan username/password, tambahkan logika di sini:
    // if (value) {
    //   await prefs.setString('savedUsername', _usernameController.text);
    //   await prefs.setString('savedPassword', _passwordController.text);
    // } else {
    //   await prefs.remove('savedUsername');
    //   await prefs.remove('savedPassword');
    // }
  }

  // Fungsi untuk menyimpan status login ke SharedPreferences
  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    // >>> START PERUBAHAN: Gunakan kunci yang konsisten
    await prefs.setBool(_prefsKeyIsLoggedIn, isLoggedIn);
    // <<< END PERUBAHAN
  }

  Future<void> _fetchInitialAccountPhoto() async {
    setState(() {
      _isInitialDataLoading = true;
    });

    final String apiUrl =
        'http://$_computerIp/$_apiBasePath/get_account_photo.php?account_type=${Uri.encodeComponent(widget.accountType)}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _initialPhotoUrl = responseData['photo_url'];
          });
        } else {
          print('Failed to fetch initial photo: ${responseData['message']}');
        }
      } else {
        print('Server error fetching initial photo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching initial photo: $e');
    } finally {
      setState(() {
        _isInitialDataLoading = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoginLoading = true;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    final String accountType = widget.accountType;

    final String apiUrl = 'http://$_computerIp/$_apiBasePath/login.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'username': username,
          'password': password,
          'account_type': accountType,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseData['message'])));

          final prefs =
              await SharedPreferences.getInstance(); // Dapatkan instance SharedPreferences

          // Simpan status login, username, dan accountType
          // >>> START PERUBAHAN: Gunakan kunci yang konsisten
          await prefs.setBool(_prefsKeyIsLoggedIn, true);
          // <<< END PERUBAHAN
          await prefs.setString('username', username); // Simpan username
          await prefs.setString(
            'accountType',
            accountType,
          ); // Simpan accountType

          // --- BARIS PENTING: SIMPAN photo_url KE SHARED PREFERENCES ---
          // Asumsi 'user_data' adalah Map dan memiliki kunci 'photo_url'
          if (responseData['user_data'] != null &&
              responseData['user_data']['photo_url'] != null) {
            await prefs.setString(
              'photo_url',
              responseData['user_data']['photo_url'],
            );
            print(
              'DEBUG LOGIN: Photo URL saved to SharedPreferences: ${responseData['user_data']['photo_url']}',
            );
          } else {
            // Jika tidak ada photo_url, pastikan dihapus atau diatur ke null
            await prefs.remove('photo_url');
            print(
              'DEBUG LOGIN: No photo URL found in user_data or user_data is null. Removed photo_url from SharedPreferences.',
            );
          }
          // --- AKHIR BARIS PENTING ---

          // Simpan status "Buat saya tetap masuk"
          if (_rememberMe) {
            // Jika Anda ingin menyimpan username/password secara otomatis, tambahkan di sini:
            // await prefs.setString('savedUsername', username);
            // await prefs.setString('savedPassword', password); // Hati-hati menyimpan password tanpa enkripsi
          } else {
            // Jika tidak "remember me", pastikan tidak ada username/password yang tersimpan
            // await prefs.remove('savedUsername');
            // await prefs.remove('savedPassword');
          }

          print('User Data: ${responseData['user_data']}');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseData['message'])));
          final prefs = await SharedPreferences.getInstance();
          // >>> START PERUBAHAN: Gunakan kunci yang konsisten
          await prefs.setBool(_prefsKeyIsLoggedIn, false);
          // <<< END PERUBAHAN
          // Hapus photo_url jika login gagal
          await prefs.remove('photo_url');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        final prefs = await SharedPreferences.getInstance();
        // >>> START PERUBAHAN: Gunakan kunci yang konsisten
        await prefs.setBool(_prefsKeyIsLoggedIn, false);
        // <<< END PERUBAHAN
        // Hapus photo_url jika ada error server
        await prefs.remove('photo_url');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('Login error: $e');
      final prefs = await SharedPreferences.getInstance();
      // >>> START PERUBAHAN: Gunakan kunci yang konsisten
      await prefs.setBool(_prefsKeyIsLoggedIn, false);
      // <<< END PERUBAHAN
      // Hapus photo_url jika ada error
      await prefs.remove('photo_url');
    } finally {
      setState(() {
        _isLoginLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    const double footerTextHeight =
        60.0; // Tinggi perkiraan untuk teks versi aplikasi
    const double paddingAboveKeyboard =
        20.0; // Padding antara elemen UI dan keyboard

    double shiftAmount =
        0.0; // Ini adalah nilai positif untuk seberapa banyak harus bergeser ke atas

    // Hanya hitung pergeseran jika keyboard muncul
    if (keyboardHeight > 0) {
      double requiredShiftForFocusedWidget = 0.0;
      if (_currentFocusedWidgetBottom > 0) {
        // Area aman di atas keyboard untuk widget yang fokus
        double safeAreaBottom =
            size.height - keyboardHeight - paddingAboveKeyboard;
        if (_currentFocusedWidgetBottom > safeAreaBottom) {
          requiredShiftForFocusedWidget =
              _currentFocusedWidgetBottom - safeAreaBottom;
        }
      }

      // Pergeseran yang dibutuhkan untuk teks footer agar tidak tertutup keyboard
      // Footer berada di `bottom: 0` dari `Stack` yang digeser.
      // Jadi, jika keyboard muncul, footer perlu diangkat setidaknya setinggi keyboard + padding.
      double requiredShiftForFooter = keyboardHeight + paddingAboveKeyboard;

      // Ambil pergeseran terbesar (yang paling tinggi) agar semua elemen terlihat
      shiftAmount = max(requiredShiftForFocusedWidget, requiredShiftForFooter);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Menyembunyikan keyboard
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Kita atur pergeseran secara manual
        backgroundColor: const Color(0xFF03112B),
        body: Stack(
          children: [
            /// BACKGROUND BIRU GRADIENT (Tidak ikut bergeser, tetap di atas)
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

            /// BACK BUTTON (Tidak ikut bergeser, tetap di posisi atas)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ),

            /// GRUP KONTEN UTAMA YANG BERGERAK (Logo, SVG Gelombang, Form, Teks Versi Aplikasi)
            // Transform.translate akan menggeser seluruh Stack ini sebagai satu kesatuan
            Transform.translate(
              offset: Offset(0, -shiftAmount), // Terapkan pergeseran ke atas
              child: Stack(
                children: [
                  /// WHITE WAVE SVG (SEBAGAI BACKGROUND UTAMA UNTUK FORM)
                  Positioned(
                    top: size.height * 0.45, // Posisi relatif terhadap layar
                    left: 0,
                    right: 0,
                    bottom: 0, // Meluas hingga ke bawah layar
                    child: RepaintBoundary(
                      child: SvgPicture.asset(
                        "assets/images/loginpage.svg",
                        width: size.width,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  /// LOGO
                  Positioned(
                    top: size.height * 0.20, // Posisi relatif terhadap layar
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        RepaintBoundary(
                          child: SvgPicture.asset(
                            "assets/images/logolengkap.svg",
                            width: size.width * 0.65,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// CONTENT LOGIN FORM (Elemen interaktif di atas SVG)
                  Positioned(
                    top: size.height * 0.52, // Posisi relatif terhadap layar
                    left: 24,
                    right: 24,
                    // Tidak ada 'bottom' agar Column mengambil tinggi alaminya
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// TITLE
                        const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03112B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TEXTFIELD USERNAME
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode, // Tambahkan FocusNode
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _buildInputDecoration(
                            // Menggunakan helper
                            labelText: 'Masukkan ID',
                            hintText: 'Masukkan ID Anda',
                          ),
                        ),
                        const SizedBox(height: 15),

                        /// TEXTFIELD PASSWORD
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode, // Tambahkan FocusNode
                          obscureText: _obscureText,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _buildInputDecoration(
                            // Menggunakan helper
                            labelText: 'Kata Sandi',
                            hintText: 'Masukkan Kata Sandi Anda',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        /// CHECKBOX "Buat saya tetap masuk"
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Buat saya tetap masuk",
                                style: TextStyle(color: Color(0xFF03112B)),
                              ),
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _rememberMe = newValue!;
                                  });
                                  _saveRememberMeState(
                                    newValue!,
                                  ); // Simpan status ke SharedPreferences
                                },
                                activeColor: const Color(0xFF03112B),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        /// BUTTON MASUK
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoginLoading ? null : _login,
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
                        const SizedBox(height: 15),

                        /// AKUN YANG DIPILIH DAN FOTO
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.accountType,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF03112B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_initialPhotoUrl != null &&
                                  _initialPhotoUrl!.isNotEmpty)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage:
                                      _initialPhotoUrl != null
                                          ? NetworkImage(_initialPhotoUrl!)
                                          : null,
                                  onBackgroundImageError: (
                                    exception,
                                    stackTrace,
                                  ) {
                                    print('Error loading image: $exception');
                                  },
                                )
                              else
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// FOOTER (Teks Versi Aplikasi) - Sekarang ikut bergerak
                  Positioned(
                    bottom: 0, // Posisikan di paling bawah dari Stack ini
                    left: 0,
                    right: 0,
                    child: Container(
                      height:
                          footerTextHeight, // Tinggi yang sama dengan sebelumnya
                      alignment: Alignment.center,
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
                ],
              ),
            ),

            /// LOADING OVERLAY (Tidak ikut bergeser, tetap di atas semua)
            if (_isInitialDataLoading || _isLoginLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color(0xFF062B59),
                      rightDotColor: const Color.fromARGB(255, 255, 255, 255),
                      size: 80,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
