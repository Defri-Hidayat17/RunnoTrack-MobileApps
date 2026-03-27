import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

// Import untuk logout
import 'package:runnotrack/loginpage.dart';

// Import UserCard yang baru
import 'package:runnotrack/widgets/usercard.dart'; // Sesuaikan path jika berbeda

// Import halaman Hubungi Kami yang baru
import 'package:runnotrack/hubungi_kami_page.dart'; // <<< TAMBAHKAN INI

// Definisi base URL untuk API Anda
const String _baseUrl = 'http://192.168.1.10/runnotrack_api';

// --- Model untuk data Pimpinan ---
class Pimpinan {
  final int id;
  final String name;
  final String department;
  final String phoneNumber;
  final String? photoUrl;
  final String? usernameLogin;
  final int? userId;

  Pimpinan({
    required this.id,
    required this.name,
    required this.department,
    required this.phoneNumber,
    this.photoUrl,
    this.usernameLogin,
    this.userId,
  });

  factory Pimpinan.fromJson(Map<String, dynamic> json) {
    return Pimpinan(
      id: int.parse(json['id'].toString()),
      name: json['pimpinan_name'] ?? 'Unknown',
      department: json['department'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? 'N/A',
      photoUrl: json['photo_url'],
      usernameLogin: json['user_login_name'],
      userId:
          json['user_id_for_link'] != null
              ? int.parse(json['user_id_for_link'].toString())
              : null,
    );
  }
}

// --- Model untuk data Operator (Checkers) ---
class Checker {
  final int id;
  final String name;
  final String groupCode;
  final String associatedAccountType;
  final String phoneNumber;
  final String? photoUrl;
  final String? usernameLogin;
  final int? userId;

  Checker({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.associatedAccountType,
    required this.phoneNumber,
    this.photoUrl,
    this.usernameLogin,
    this.userId,
  });

  factory Checker.fromJson(Map<String, dynamic> json) {
    return Checker(
      id: int.parse(json['id'].toString()),
      name: json['checker_name'] ?? 'Unknown',
      groupCode: json['group_code'] ?? 'N/A',
      associatedAccountType: json['associated_account_type'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? 'N/A',
      photoUrl: json['photo_url'],
      usernameLogin: json['user_login_name'],
      userId:
          json['user_id_for_link'] != null
              ? int.parse(json['user_id_for_link'].toString())
              : null,
    );
  }
}

class ProfilPage extends StatefulWidget {
  final String loggedInUserAccountType;
  final String? loggedInUserPhotoUrl;
  final String? loggedInUsername;

  const ProfilPage({
    super.key,
    required this.loggedInUserAccountType,
    this.loggedInUserPhotoUrl,
    this.loggedInUsername,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  int _selectedTabIndex = 0; // 0: Profil, 1: Pengaturan, 2: Notifikasi
  String _selectedCheckerCategory = 'Pimpinan'; // 'Pimpinan' atau 'Operator'

  // Data untuk menampilkan daftar Pimpinan/Operator
  List<Pimpinan> _pimpinanList = [];
  List<Checker> _checkersList = [];
  bool _isLoadingData = true;
  String? _errorMessageData;

  // State untuk pengaturan notifikasi
  bool _enableNotificationSound = true;
  bool _enableNotificationVibration = true;
  bool _showNotifications = true;

  // ⚙️ 2. INIT (WAJIB)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // 🚀 3. INIT DI initState()
    _initNotification();
    _loadNotificationSettings();
    _fetchMembersData(); // Mengambil data Pimpinan dan Checker
  }

  // 🚀 3. INIT DI initState() - _initNotification() function
  void _initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // --- Logika Pengaturan Notifikasi ---
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotificationSound =
          prefs.getBool('enableNotificationSound') ?? true;
      _enableNotificationVibration =
          prefs.getBool('enableNotificationVibration') ?? true;
      _showNotifications = prefs.getBool('showNotifications') ?? true;
    });
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableNotificationSound', _enableNotificationSound);
    await prefs.setBool(
      'enableNotificationVibration',
      _enableNotificationVibration,
    );
    await prefs.setBool('showNotifications', _showNotifications);
    _showSnackBar('Pengaturan notifikasi berhasil disimpan!');
  }

  // --- Logika Pengambilan Data Pimpinan dan Checker (read-only) ---
  Future<void> _fetchMembersData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessageData = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/get_admin_data.php?account_type=${widget.loggedInUserAccountType}',
        ),
      );
      print("LOGIN ACCOUNT TYPE: ${widget.loggedInUserAccountType}");

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success']) {
          List<Pimpinan> fetchedPimpinan =
              (decodedResponse['pimpinan'] as List)
                  .map((data) => Pimpinan.fromJson(data))
                  .toList();
          List<Checker> fetchedCheckers =
              (decodedResponse['checkers'] as List)
                  .map((data) => Checker.fromJson(data))
                  .toList();

          setState(() {
            _pimpinanList = fetchedPimpinan;
            _checkersList = fetchedCheckers;
          });
        } else {
          _errorMessageData =
              decodedResponse['message'] ?? 'Gagal mengambil data.';
        }
      } else {
        _errorMessageData = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessageData = 'Error koneksi: $e';
      print('Error fetching members data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // --- Helper UI Umum ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // --- Fungsi untuk menampilkan gambar dalam dialog (seperti WhatsApp) ---
  void _showImageDialog(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // Membuat rute transparan
        pageBuilder: (BuildContext context, _, __) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context); // Menutup tampilan gambar saat di-tap
            },
            child: Scaffold(
              backgroundColor: Colors.black, // Latar belakang hitam penuh
              body: Center(
                child: Stack(
                  children: [
                    InteractiveViewer(
                      // Untuk zoom dan pan gambar
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.1,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    Positioned(
                      top:
                          MediaQuery.of(context).padding.top +
                          16, // Sesuaikan dengan status bar
                      left: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔊 4. FUNCTION UNTUK TRIGGER NOTIF (INI KUNCINYA)
  Future<void> _showSystemNotification() async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,

          // 🔥 INI KUNCI NYA
          playSound: _enableNotificationSound,
          enableVibration: _enableNotificationVibration,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notifikasi Test',
      'Cek suara & getar',
      notificationDetails,
    );
  }

  // --- Fungsi untuk membuka WhatsApp ---
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Format nomor telepon ke format internasional tanpa '+'
    // Contoh: '085775680671' menjadi '6285775680671'
    String formattedPhoneNumber =
        phoneNumber.startsWith('0')
            ? '62${phoneNumber.substring(1)}'
            : phoneNumber;
    if (!formattedPhoneNumber.startsWith('62')) {
      formattedPhoneNumber = '62$formattedPhoneNumber';
    }

    final Uri whatsappUrl = Uri.parse('https://wa.me/$formattedPhoneNumber');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      _showSnackBar('Tidak dapat membuka WhatsApp untuk nomor ini.');
    }
  }

  // --- Logika Logout ---
  Future<void> _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Zona Berbahaya ⚠️",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const Text("Apakah kamu yakin ingin logout dari akun ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Logout"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Hapus semua data SharedPreferences
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Hapus semua route sebelumnya
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menghitung tinggi navbar + padding yang dibutuhkan
    // Tinggi navbar default Flutter adalah sekitar 56.0 (jika menggunakan BottomNavigationBar)
    // Ditambah padding 35 yang Anda sebutkan untuk navbar
    // Tambahan sedikit buffer agar lebih aman, misalnya 20.0
    final double bottomNavbarHeight =
        MediaQuery.of(context).padding.bottom + 56.0 + 35.0 + 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- Bagian Header Profil (FIXED) ---
          Container(
            padding: const EdgeInsets.only(
              top: 5,
              bottom: 20, // Kembali ke 20 untuk spacing yang baik
              left: 16,
              right: 16,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                GestureDetector(
                  // Menambahkan GestureDetector untuk klik gambar
                  onTap: () {
                    if (widget.loggedInUserPhotoUrl != null &&
                        widget.loggedInUserPhotoUrl!.isNotEmpty) {
                      _showImageDialog(context, widget.loggedInUserPhotoUrl!);
                    }
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        widget.loggedInUserPhotoUrl != null &&
                                widget.loggedInUserPhotoUrl!.isNotEmpty
                            ? NetworkImage(widget.loggedInUserPhotoUrl!)
                            : null,
                    child:
                        widget.loggedInUserPhotoUrl == null ||
                                widget.loggedInUserPhotoUrl!.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Username yang dipakai buat login
              ],
            ),
          ),
          // --- Navigation Tabs (FIXED) ---
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10, // Mengurangi margin vertikal agar lebih mepet
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2547),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(0, Icons.person, 'Profil'),
                _buildTabItem(1, Icons.settings, 'Pengaturan'),
                _buildTabItem(2, Icons.notifications, 'Notifikasi'),
              ],
            ),
          ),
          // --- Konten berdasarkan tab yang dipilih (DYNAMICALLY SCROLLABLE) ---
          Expanded(
            // Expanded ini memastikan sisa ruang diambil oleh konten di bawahnya
            child: Container(
              // Ini adalah box biru muda utama untuk semua tab
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFDBE6F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  _selectedTabIndex == 0
                      ? Column(
                        // Untuk tab Profil: tombol kategori fixed + daftar scrollable
                        children: [
                          // Filter Pimpinan / Operator (fixed di dalam box biru muda)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _buildCategoryButton('Pimpinan'),
                                _buildCategoryButton('Operator'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Scrollable list of members
                          Expanded(
                            // Expanded ini penting agar SingleChildScrollView mengambil sisa ruang
                            child: SingleChildScrollView(
                              // Padding bawah disesuaikan agar tidak terpotong navbar
                              padding: EdgeInsets.only(
                                bottom: bottomNavbarHeight,
                              ),
                              child:
                                  _isLoadingData
                                      ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                        ),
                                      )
                                      : _errorMessageData != null
                                      ? Center(
                                        child: Text(
                                          'Error: $_errorMessageData',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                      : _buildMemberList(),
                            ),
                          ),
                        ],
                      )
                      : SingleChildScrollView(
                        // Untuk tab Pengaturan dan Notifikasi: seluruh konten di-scroll
                        // Padding bawah disesuaikan agar tidak terpotong navbar
                        padding: EdgeInsets.only(bottom: bottomNavbarHeight),
                        child:
                            _buildTabContent(), // Ini akan mengembalikan Column untuk pengaturan/notifikasi
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF03112B) : Colors.white,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF03112B) : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildTabContent sekarang hanya mengembalikan widget konten untuk Pengaturan dan Notifikasi
  // Untuk Profil, kontennya ditangani langsung di `build` method utama
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return Container(); // Konten profil ditangani di luar fungsi ini
      case 1:
        return _buildPengaturanContent();
      case 2:
        return _buildNotifikasiContent();
      default:
        return Container();
    }
  }

  Widget _buildCategoryButton(String category) {
    bool isSelected = _selectedCheckerCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCheckerCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D2547) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    List<dynamic> currentList =
        _selectedCheckerCategory == 'Pimpinan' ? _pimpinanList : _checkersList;
    if (currentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Tidak ada data ${_selectedCheckerCategory} untuk ditampilkan.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Memastikan ListView tidak scroll sendiri
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final item = currentList[index];
        return _buildMemberListItem(item);
      },
    );
  }

  Widget _buildMemberListItem(dynamic item) {
    String name;
    String accountType;
    String? groupCode;
    String phoneNumber;
    String? photoUrl;

    if (item is Pimpinan) {
      name = item.name;
      accountType =
          item.department; // Department sebagai accountType untuk Pimpinan
      groupCode = null; // Pimpinan tidak punya group_code
      phoneNumber = item.phoneNumber;
      photoUrl = item.photoUrl;
    } else if (item is Checker) {
      name = item.name;
      accountType = item.associatedAccountType;
      groupCode = item.groupCode;
      phoneNumber = item.phoneNumber;
      photoUrl = item.photoUrl;
    } else {
      return const SizedBox.shrink(); // Seharusnya tidak terjadi
    }

    return UserCard(
      name: name,
      accountType: accountType,
      groupCode: groupCode,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      onTapImage: () {
        if (photoUrl != null && photoUrl.isNotEmpty) {
          _showImageDialog(context, photoUrl);
        }
      },
      onTapWhatsApp: () {
        _launchWhatsApp(phoneNumber);
      },
    );
  }

  // --- Konten Pengaturan yang Diperbarui (Termasuk Tombol Logout dan Hubungi Kami) ---
  Widget _buildPengaturanContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan Umum',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF03112B),
          ),
        ),
        const SizedBox(height: 20),

        // --- Hubungi Kami Section ---
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(
            bottom: 10,
          ), // Tambahkan sedikit margin bawah
          child: InkWell(
            // Menggunakan InkWell agar Card bisa diklik
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HubungiKamiPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Hubungi Kami',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF03112B),
                    ),
                  ),
                  Icon(
                    Icons.phone,
                    color: Color(0xFF0D2547),
                  ), // Ikon telepon dari Flutter
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10), // Spasi setelah Hubungi Kami
        // Tombol Logout yang lebih modern dan rapi
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero, // Tidak ada margin tambahan dari Card
          child: InkWell(
            // Menggunakan InkWell agar Card bisa diklik
            onTap: _logout,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Logout dari Akun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red, // Warna merah untuk logout
                    ),
                  ),
                  Icon(Icons.logout, color: Colors.red),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10), // Spasi setelah tombol logout
        Text(
          'Keluar dari akun Anda saat ini. Anda akan diminta untuk masuk kembali.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  // --- Konten Notifikasi yang Diperbarui (Modern dan Rapi) ---
  Widget _buildNotifikasiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            fontSize: 20, // Ukuran font lebih besar untuk judul
            fontWeight: FontWeight.bold,
            color: Color(0xFF03112B),
          ),
        ),
        const SizedBox(height: 15), // Spasi setelah judul
        // Card untuk "Tampilkan Notifikasi"
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Tampilkan Notifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF03112B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aktifkan atau nonaktifkan semua notifikasi.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _showNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      _showNotifications = value;
                      // Jika notifikasi utama dimatikan, matikan juga suara dan getar
                      if (!value) {
                        _enableNotificationSound = false;
                        _enableNotificationVibration = false;
                      }
                    });
                  },
                  activeColor: const Color(0xFF0D2547),
                ),
              ],
            ),
          ),
        ),

        // Card untuk "Aktifkan Suara Notifikasi"
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktifkan Suara Notifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              _showNotifications
                                  ? const Color(0xFF03112B)
                                  : Colors.grey, // Warna teks dinonaktifkan
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Putar suara saat notifikasi diterima.',
                        style: TextStyle(
                          color:
                              _showNotifications
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableNotificationSound,
                  onChanged:
                      _showNotifications // Hanya bisa diubah jika notifikasi utama aktif
                          ? (bool value) async {
                            setState(() {
                              _enableNotificationSound = value;
                            });
                            if (value) {
                              await _showSystemNotification();
                            }
                          }
                          : null, // Dinonaktifkan jika _showNotifications false
                  activeColor: const Color(0xFF0D2547),
                ),
              ],
            ),
          ),
        ),

        // Card untuk "Aktifkan Getar Notifikasi"
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktifkan Getar Notifikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              _showNotifications
                                  ? const Color(0xFF03112B)
                                  : Colors.grey, // Warna teks dinonaktifkan
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Getarkan perangkat saat notifikasi diterima.',
                        style: TextStyle(
                          color:
                              _showNotifications
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableNotificationVibration,
                  onChanged:
                      _showNotifications // Hanya bisa diubah jika notifikasi utama aktif
                          ? (bool value) async {
                            setState(() {
                              _enableNotificationVibration = value;
                            });
                            if (value) {
                              await _showSystemNotification();
                            }
                          }
                          : null, // Dinonaktifkan jika _showNotifications false
                  activeColor: const Color(0xFF0D2547),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20), // Spasi sebelum tombol simpan
        ElevatedButton(
          onPressed: _saveNotificationSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D2547),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ), // Sesuaikan dengan radius Card
            ),
          ),
          child: const Text(
            'Simpan Pengaturan Notifikasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ), // Ukuran font tombol
          ),
        ),
      ],
    );
  }
}
