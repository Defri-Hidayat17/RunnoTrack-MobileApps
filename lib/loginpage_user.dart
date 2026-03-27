import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'loginpage.dart';
import 'homepage.dart';
import 'admin_main_scaffold.dart';

class LoginPageUser extends StatefulWidget {
  final String accountType;

  const LoginPageUser({super.key, required this.accountType});

  @override
  State<LoginPageUser> createState() => _LoginPageUserState();
}

class _LoginPageUserState extends State<LoginPageUser> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  double _currentFocusedWidgetBottom = 0.0;

  bool _isLoginLoading = false;
  bool _isInitialDataLoading = true;
  bool _obscureText = true;
  bool _rememberMe = false;

  String? _initialPhotoUrl;

  static const String _computerIp = '192.168.1.10';
  static const String _apiBasePath = 'runnotrack_api';
  static const String _prefsKeyIsLoggedIn = 'is_logged_in';
  static const String _prefsKeyName = 'name';
  static const String _prefsKeyRole =
      'user_role'; // 🔥 PENTING: Kunci ini HARUS SAMA dengan yang di SplashScreen
  static const String _prefsKeyAccountType =
      'user_account_type'; // Kunci ini masih disimpan, tapi SplashScreen tidak menggunakannya untuk routing

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
    _loadRememberMeState();
    _fetchInitialAccountPhoto();
    _usernameFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_usernameFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      final RenderBox? renderBox =
          (_usernameFocusNode.hasFocus
                  ? _usernameFocusNode.context?.findRenderObject()
                  : _passwordFocusNode.context?.findRenderObject())
              as RenderBox?;

      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _currentFocusedWidgetBottom = offset.dy + renderBox.size.height;
        });
      }
    } else {
      setState(() {
        _currentFocusedWidgetBottom = 0.0;
      });
    }
  }

  Future<void> _loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  // Fungsi ini tidak lagi diperlukan karena status login diatur langsung di _login
  // Future<void> _saveLoginStatus(bool isLoggedIn) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool(_prefsKeyIsLoggedIn, isLoggedIn);
  // }

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

      final prefs = await SharedPreferences.getInstance();

      // 🔥 PENTING: Selalu hapus data login sebelumnya untuk memastikan status bersih
      await prefs.remove(_prefsKeyIsLoggedIn);
      await prefs.remove(_prefsKeyName);
      await prefs.remove(_prefsKeyRole);
      await prefs.remove(_prefsKeyAccountType);
      await prefs.remove('photo_url');
      await prefs.remove('user_id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Hanya tampilkan snackbar sukses jika login benar-benar berhasil
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'])));

          // Pastikan user_data tidak null
          if (responseData['user_data'] != null) {
            final String userRole = responseData['user_data']['role'] ?? '';

            // 🔥 VALIDASI ROLE: Login dianggap sukses hanya jika role tidak kosong
            if (userRole.isNotEmpty) {
              await prefs.setBool(_prefsKeyIsLoggedIn, true);
              await prefs.setString('username', username);
              await prefs.setString(_prefsKeyAccountType, accountType);
              await prefs.setString(
                _prefsKeyName,
                responseData['user_data']['name'] ?? '',
              );
              await prefs.setString(
                _prefsKeyRole,
                userRole,
              ); // Simpan role yang sudah divalidasi

              if (responseData['user_data']['photo_url'] != null) {
                await prefs.setString(
                  'photo_url',
                  responseData['user_data']['photo_url'],
                );
                print(
                  'DEBUG LOGIN: Photo URL saved to SharedPreferences: ${responseData['user_data']['photo_url']}',
                );
              }
              if (responseData['user_data']['user_id'] != null) {
                await prefs.setString(
                  'user_id',
                  responseData['user_data']['user_id'].toString(),
                );
                print(
                  'DEBUG LOGIN: User ID saved to SharedPreferences: ${responseData['user_data']['user_id']}',
                );
              }

              print('User Data: ${responseData['user_data']}');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(responseData['message'])));

              // 🔥 NAVIGASI YANG DIPERBARUI: Lebih sederhana dan sesuai dengan DB Anda
              if (accountType == 'Admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminMainScaffold(),
                  ),
                );
              } else {
                // Semua accountType lain (seperti 'Kaishi Picking', 'CrossLine') akan masuk ke HomePage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
            } else {
              // Jika role kosong meskipun status sukses, anggap login gagal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Login gagal: Peran pengguna tidak ditemukan. Silakan coba lagi atau hubungi dukungan.',
                  ),
                ),
              );
              print(
                'WARNING: Login successful but user role is empty or null from API. Not navigating.',
              );
              // Tidak perlu set isLoggedIn ke false karena sudah dihapus di awal, dan tidak di set true
            }
          } else {
            // Jika user_data null meskipun status sukses, ada masalah API
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Login gagal: Data pengguna tidak lengkap. Silakan coba lagi atau hubungi dukungan.',
                ),
              ),
            );
            print(
              'ERROR: Login successful but user_data is null from API. Not navigating.',
            );
          }
        } else {
          // Login gagal dari API (misal: username/password salah)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        }
      } else {
        // Server error (misal: 404, 500)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Error jaringan atau parsing
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('Login error: $e');
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
    const double footerTextHeight = 60.0;
    const double paddingAboveKeyboard = 20.0;

    double shiftAmount = 0.0;

    if (keyboardHeight > 0) {
      double requiredShiftForFocusedWidget = 0.0;
      if (_currentFocusedWidgetBottom > 0) {
        double safeAreaBottom =
            size.height - keyboardHeight - paddingAboveKeyboard;
        if (_currentFocusedWidgetBottom > safeAreaBottom) {
          requiredShiftForFocusedWidget =
              _currentFocusedWidgetBottom - safeAreaBottom;
        }
      }

      double requiredShiftForFooter = keyboardHeight + paddingAboveKeyboard;
      shiftAmount = max(requiredShiftForFocusedWidget, requiredShiftForFooter);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF03112B),
        body: Stack(
          children: [
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
            Transform.translate(
              offset: Offset(0, -shiftAmount),
              child: Stack(
                children: [
                  Positioned(
                    top: size.height * 0.45,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: RepaintBoundary(
                      child: SvgPicture.asset(
                        "assets/images/loginpage.svg",
                        width: size.width,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.20,
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
                  Positioned(
                    top: size.height * 0.52,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _buildInputDecoration(
                            labelText: 'Masukkan ID',
                            hintText: 'Masukkan ID Anda',
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscureText,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: _buildInputDecoration(
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
                                  _saveRememberMeState(newValue!);
                                },
                                activeColor: const Color(0xFF03112B),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
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
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: footerTextHeight,
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
            if (_isInitialDataLoading || _isLoginLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: LoadingAnimationWidget.twistingDots(
                      leftDotColor: const Color.fromARGB(255, 9, 111, 236),
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
