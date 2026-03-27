import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Bottom Navigation Bar khusus admin
import 'admin_bottom_navigation_bar.dart';

// Import halaman-halaman admin
import 'riwayatpage_admin.dart';
import 'profilpage_admin.dart'; // Pastikan ini mengarah ke file yang benar

class AdminMainScaffold extends StatefulWidget {
  const AdminMainScaffold({super.key});

  @override
  State<AdminMainScaffold> createState() => _AdminMainScaffoldState();
}

class _AdminMainScaffoldState extends State<AdminMainScaffold> {
  int _selectedIndex = 0; // Default ke Riwayat (index 0)
  String? _loggedInUsername;
  String? _loggedInAccountType;
  String? _profileImageFilename;
  String?
  _loggedInUserIdString; // Variabel untuk string ID dari SharedPreferences
  int _loggedInUserId = 0; // Variabel int untuk ID user Admin
  String? _loggedInName;

  bool _isLoadingUserData = true;

  late List<Widget> _adminPages;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserData();
  }

  Future<void> _loadLoggedInUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username');
      _loggedInAccountType = prefs.getString('accountType');
      _profileImageFilename = prefs.getString('photo_url');
      _loggedInUserIdString = prefs.getString(
        'user_id',
      ); // Ambil sebagai string
      _loggedInName = prefs.getString('name');

      // Parse _loggedInUserIdString ke int untuk digunakan oleh fitur ganti password admin
      if (_loggedInUserIdString != null) {
        _loggedInUserId = int.tryParse(_loggedInUserIdString!) ?? 0;
      } else {
        _loggedInUserId = 0; // Default jika tidak ada ID atau gagal parse
        print('Warning: loggedInUserId is null or could not be parsed.');
      }

      // Inisialisasi halaman admin setelah data user dimuat
      _adminPages = [
        const RiwayatpageAdmin(),
        ProfilPageAdmin(
          loggedInUsername: _loggedInName ?? _loggedInUsername ?? 'Admin',
          loggedInUserAccountType: _loggedInAccountType ?? 'Admin',
          loggedInUserPhotoUrl: _profileImageFilename, // Bisa null
          loggedInUserId:
              _loggedInUserId, // ID user Admin diteruskan untuk fitur ganti password
        ),
      ];
      _isLoadingUserData = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String textToDisplay = _loggedInName ?? _loggedInUsername ?? 'Admin';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(textToDisplay),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _adminPages[_selectedIndex], // Tampilkan halaman yang dipilih
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: AdminPillBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String displayName) {
    String? fullProfileImageUrl;
    if (_profileImageFilename != null && _profileImageFilename!.isNotEmpty) {
      fullProfileImageUrl = _profileImageFilename;
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(110.0),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0D2547),
            padding: const EdgeInsets.only(
              top: 50.0,
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/logolengkap.svg', height: 35),
                GestureDetector(
                  onTap: () {
                    _onItemTapped(1); // Navigasi ke Profil (index 1)
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipOval(
                          child:
                              (fullProfileImageUrl != null &&
                                      fullProfileImageUrl.startsWith('http'))
                                  ? Image.network(
                                    fullProfileImageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (
                                      BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      );
                                    },
                                  )
                                  : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),
          Container(height: 8.0, color: const Color(0xFF0D2547)),
        ],
      ),
    );
  }
}
