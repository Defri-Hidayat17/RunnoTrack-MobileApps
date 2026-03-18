import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Import untuk fungsi max

// Import halaman-halaman navigasi (pastikan file ini ada)
import 'package:runnotrack/hasilpage.dart';
import 'package:runnotrack/riwayatpage.dart';
import 'package:runnotrack/profilpage.dart';

// Import PillBottomNavigationBar dari file terpisah yang baru
import 'package:runnotrack/bottomnavigationbar.dart';

// Import CardData dan DynamicCard dari file terpisah yang baru
import 'package:runnotrack/models/card_data.dart'; // Pastikan path ini benar
import 'package:runnotrack/dynamic_card.dart'; // Pastikan path ini benar

// Definisi base URL untuk API Anda
// PASTIKAN IP INI SESUAI DENGAN IP KOMPUTER/SERVER ANDA
const String _baseUrl = 'http://192.168.1.10/runnotrack_api';

/// Widget utama aplikasi yang menangani navigasi antar halaman dan AppBar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _loggedInUsername;
  String? _loggedInAccountType;
  String? _profileImageFilename;

  // List halaman yang akan ditampilkan di body Scaffold
  // Gunakan const untuk halaman yang tidak berubah untuk optimasi.
  final List<Widget> _pages = const [
    _HomeContentPage(), // Konten untuk tab "Home" (Index 0)
    Hasilpage(), // Index 1
    RiwayatPage(), // Index 2
    ProfilPage(), // Index 3
  ];

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Memastikan data user dimuat ulang jika ada perubahan (misal setelah login/logout)
    _loadLoggedInUserData();
  }

  Future<void> _loadLoggedInUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username');
      _loggedInAccountType = prefs.getString('accountType');
      _profileImageFilename = prefs.getString('photo_url');
      // print('DEBUG APP BAR: Loaded username: $_loggedInUsername');
      // print('DEBUG APP BAR: Loaded accountType: $_loggedInAccountType');
      // print(
      //   'DEBUG APP BAR: Loaded profileImageFilename (from SharedPreferences): $_profileImageFilename',
      // );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      resizeToAvoidBottomInset: false, // Tetap false seperti permintaan Anda
      body: Stack(
        children: [
          /// PAGE CONTENT
          // Menggunakan Builder untuk mendapatkan BuildContext yang tepat
          // agar MediaQuery.of(context) di _HomeContentPage bisa bekerja
          // dengan benar terkait keyboard.
          Builder(
            builder: (context) {
              return IndexedStack(index: _selectedIndex, children: _pages);
            },
          ),

          /// FLOATING NAVBAR (OVERLAY)
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: PillBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget AppBar Kustom ---
  PreferredSizeWidget _buildAppBar() {
    String? fullProfileImageUrl;
    if (_profileImageFilename != null && _profileImageFilename!.isNotEmpty) {
      // Asumsi _profileImageFilename sudah berupa URL lengkap
      // Jika hanya nama file, Anda perlu menambahkan base URL server Anda
      // Contoh: fullProfileImageUrl = '$_baseUrl/uploads/$_profileImageFilename';
      fullProfileImageUrl = _profileImageFilename;
    }

    String userDisplayName = _loggedInUsername ?? 'User';
    String accountTypeDisplay = _loggedInAccountType ?? '';
    String textToDisplay =
        accountTypeDisplay.isNotEmpty ? accountTypeDisplay : userDisplayName;

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
                    _onItemTapped(3); // Indeks 3 adalah ProfilPage
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        textToDisplay,
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
                                          color:
                                              Colors.white, // Warna indikator
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                    errorBuilder: (
                                      BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace,
                                    ) {
                                      // print(
                                      //   'DEBUG APP BAR: Failed to load image from URL: $fullProfileImageUrl',
                                      // );
                                      // print(
                                      //   'DEBUG APP BAR: Image loading exception: $exception',
                                      // );
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

/// Konten spesifik untuk Tab "Home" yang akan ditampilkan di dalam HomePage.
class _HomeContentPage extends StatefulWidget {
  const _HomeContentPage({super.key});

  @override
  State<_HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<_HomeContentPage>
    with SingleTickerProviderStateMixin {
  // --- Styling Umum untuk Input Box ---
  static const Color _darkBlueStrokeColor = Color(0xFF03112B);
  static const List<BoxShadow> _commonBoxShadow = [
    BoxShadow(
      color: Colors.grey,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  Widget _buildInputContainer({
    Key? key,
    required Widget child,
    bool isDisabled = false,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color:
            isDisabled
                ? Colors.grey[200]
                : Colors.white, // Warna abu-abu jika disabled
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _darkBlueStrokeColor, width: 1.0),
        boxShadow: _commonBoxShadow,
      ),
      child: child,
    );
  }

  InputDecoration _commonTextFormFieldDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      suffixIcon: suffixIcon,
    );
  }
  // --- Akhir Styling Umum ---

  // Kunci untuk SharedPreferences
  static const String _prefsKeySelectedDate =
      'selectedTrackingDate'; // Kunci baru untuk tanggal
  static const String _prefsKeySelectedGroup = 'selected_group';
  static const String _prefsKeySelectedUser = 'selected_user';
  static const String _prefsKeyTotalTarget = 'total_target';
  static const String _prefsKeySavedCards = 'saved_cards';
  static const String _prefsKeyNextCardId = 'next_card_id';

  String _selectedDate = DateFormat(
    'dd/MM/yy',
  ).format(DateTime.now()); // Inisialisasi langsung dengan tanggal saat ini
  String? _selectedGroup;
  String? _selectedUser;
  final TextEditingController _totalTargetController = TextEditingController();
  List<CardData> _cards = []; // Diharapkan hanya berisi maksimal 1 CardData

  List<String> _availableGroups = [];
  List<String> _availableCheckers = [];

  String? _loggedInAccountType;
  int _nextCardId = 1; // Variabel state untuk ID kartu berikutnya

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Dropdown state variables for group and checker
  final GlobalKey _groupDropdownKey = GlobalKey();
  bool _isGroupDropdownOpen = false;
  OverlayEntry? _groupOverlayEntry;

  final GlobalKey _checkerDropdownKey = GlobalKey();
  bool _isCheckerDropdownOpen = false;
  OverlayEntry? _checkerOverlayEntry;

  // NEW: State variable untuk mengunci checker
  bool _isCheckerLocked = false;

  // --- Fungsi _showSnackBar ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }
  // --- Akhir Fungsi _showSnackBar ---

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadLoggedInUserDataFromPrefs();
      // Panggil _fetchGroups terlebih dahulu untuk mengisi _availableGroups
      await _fetchGroups();

      // Sekarang muat sisa state, termasuk tanggal, grup/pengguna yang dipilih
      await _loadCurrentState();

      // Setelah semua data dimuat, periksa apakah checker harus dikunci
      _checkIfEntryExistsAndLockChecker();

      setState(() {}); // Pastikan UI diperbarui setelah semua pemuatan
    });

    // HAPUS LISTENER INI. _totalTargetController akan disimpan saat kartu disave.
    // _totalTargetController.addListener(_onTotalTargetChanged);
  }

  @override
  void dispose() {
    // HAPUS LISTENER INI.
    // _totalTargetController.removeListener(_onTotalTargetChanged);
    _totalTargetController.dispose();
    _animationController.dispose();
    _groupOverlayEntry?.remove();
    _checkerOverlayEntry?.remove();
    super.dispose();
  }

  // HAPUS FUNGSI INI.
  // void _onTotalTargetChanged() {
  //   _saveCurrentState(); // Simpan state setiap kali total target berubah
  // }

  // Getter baru untuk menentukan apakah tombol "Add" harus aktif
  // Tombol "Add" hanya aktif jika tidak ada kartu yang sedang ditampilkan.
  bool get _canAddCard {
    return _cards.isEmpty;
  }

  Future<void> _loadLoggedInUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInAccountType = prefs.getString('accountType');
    // print(
    //   'DEBUG LOAD: _loggedInAccountType loaded: $_loggedInAccountType',
    // ); // DEBUG
  }

  Future<void> _loadCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    // print('DEBUG LOAD: Starting _loadCurrentState...'); // DEBUG

    // --- Muat Tanggal ---
    final String? savedDateString = prefs.getString(_prefsKeySelectedDate);
    if (savedDateString != null) {
      _selectedDate = savedDateString;
      // print('DEBUG LOAD: _selectedDate loaded: $_selectedDate'); // DEBUG
    } else {
      _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
      // print(
      //   'DEBUG LOAD: No _selectedDate saved, defaulting to: $_selectedDate',
      // ); // DEBUG
    }

    // Muat total target
    final String? savedTotalTarget = prefs.getString(_prefsKeyTotalTarget);
    if (savedTotalTarget != null && savedTotalTarget.isNotEmpty) {
      _totalTargetController.text = savedTotalTarget;
      // print(
      //   'DEBUG LOAD: _totalTargetController loaded: $savedTotalTarget',
      // ); // DEBUG
    } else {
      // print('DEBUG LOAD: No _totalTargetController saved.'); // DEBUG
    }

    // Muat kartu
    final String? cardsJson = prefs.getString(_prefsKeySavedCards);
    if (cardsJson != null && cardsJson != '[]') {
      // Pastikan bukan string kosong atau array kosong
      try {
        final List<dynamic> decodedData = json.decode(cardsJson);
        if (decodedData.isNotEmpty) {
          _cards = [CardData.fromJson(decodedData.first)];
          // print(
          //   'DEBUG LOAD: Card loaded: ${_cards.first.model} with ID: ${_cards.first.id}',
          // ); // DEBUG
        } else {
          _cards = [];
          // print('DEBUG LOAD: No cards found in SharedPreferences.'); // DEBUG
        }
      } catch (e) {
        // print('DEBUG LOAD: Error decoding saved cards: $e'); // DEBUG
        _showSnackBar('Error memuat kartu tersimpan: $e');
        await prefs.remove(_prefsKeySavedCards);
      }
    } else {
      _cards = []; // Pastikan _cards kosong jika tidak ada data yang valid
      // print('DEBUG LOAD: No cards JSON found or it was empty.'); // DEBUG
    }

    // Muat grup
    final String? savedGroup = prefs.getString(_prefsKeySelectedGroup);
    // print('DEBUG LOAD: savedGroup from prefs: $savedGroup'); // DEBUG
    String? tempSelectedGroup;
    if (savedGroup != null && _availableGroups.contains(savedGroup)) {
      tempSelectedGroup = savedGroup;
      // print('DEBUG LOAD: savedGroup ($savedGroup) is valid.'); // DEBUG
    } else if (_availableGroups.isNotEmpty) {
      // Jika tidak ada grup yang disimpan atau tidak valid, coba atur default dari grup yang tersedia
      tempSelectedGroup =
          _availableGroups.contains('A') ? 'A' : _availableGroups.first;
      // print(
      //   'DEBUG LOAD: savedGroup ($savedGroup) invalid or null, defaulting to: $tempSelectedGroup',
      // ); // DEBUG
    } else {
      // print(
      //   'DEBUG LOAD: _availableGroups is empty, cannot set default group.',
      // ); // DEBUG
    }
    _selectedGroup = tempSelectedGroup;
    // print(
    //   'DEBUG LOAD: _selectedGroup after processing: $_selectedGroup',
    // ); // DEBUG

    // Jika grup dipilih (baik dimuat atau default), ambil checker untuk grup tersebut
    if (_selectedGroup != null && _loggedInAccountType != null) {
      // print(
      //   'DEBUG LOAD: Fetching checkers for group: $_selectedGroup and account type: $_loggedInAccountType',
      // ); // DEBUG
      await _fetchCheckersByGroup(_selectedGroup!, _loggedInAccountType!);
      // print(
      //   'DEBUG LOAD: _availableCheckers after fetch: $_availableCheckers',
      // ); // DEBUG

      // Setelah checker diambil, coba muat pengguna yang dipilih
      final String? savedUser = prefs.getString(_prefsKeySelectedUser);
      // print('DEBUG LOAD: savedUser from prefs: $savedUser'); // DEBUG
      if (savedUser != null && _availableCheckers.contains(savedUser)) {
        _selectedUser = savedUser;
        // print(
        //   'DEBUG LOAD: savedUser ($savedUser) is valid and found in _availableCheckers.',
        // ); // DEBUG
      } else {
        _selectedUser = null; // Reset jika tidak ditemukan atau tidak valid
        // print(
        //   'DEBUG LOAD: savedUser ($savedUser) invalid or not found in _availableCheckers. Resetting _selectedUser to null.',
        // ); // DEBUG
      }
    } else {
      _selectedUser = null; // Tidak ada grup, tidak ada pengguna yang dipilih
      // print(
      //   'DEBUG LOAD: _selectedGroup or _loggedInAccountType is null. Cannot fetch checkers.',
      // ); // DEBUG
    }
    // print(
    //   'DEBUG LOAD: _selectedUser after processing: $_selectedUser',
    // ); // DEBUG

    // Muat next card ID
    _nextCardId = prefs.getInt(_prefsKeyNextCardId) ?? 1;
    // print('DEBUG LOAD: _nextCardId loaded: $_nextCardId'); // DEBUG

    // print('DEBUG LOAD: _loadCurrentState finished.'); // DEBUG
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    // --- Simpan Tanggal ---
    await prefs.setString(_prefsKeySelectedDate, _selectedDate);
    // print('DEBUG SAVE: _selectedDate saved: $_selectedDate'); // DEBUG

    // Simpan grup
    if (_selectedGroup != null) {
      await prefs.setString(_prefsKeySelectedGroup, _selectedGroup!);
      // print('DEBUG SAVE: _selectedGroup saved: $_selectedGroup'); // DEBUG
    } else {
      await prefs.remove(_prefsKeySelectedGroup);
      // print('DEBUG SAVE: _selectedGroup removed.'); // DEBUG
    }

    // Simpan pengguna
    if (_selectedUser != null) {
      await prefs.setString(_prefsKeySelectedUser, _selectedUser!);
      // print('DEBUG SAVE: _selectedUser saved: $_selectedUser'); // DEBUG
    } else {
      await prefs.remove(_prefsKeySelectedUser);
      // print('DEBUG SAVE: _selectedUser removed.'); // DEBUG
    }

    // Simpan total target
    await prefs.setString(_prefsKeyTotalTarget, _totalTargetController.text);
    // print(
    //   'DEBUG SAVE: _totalTargetController saved: ${_totalTargetController.text}',
    // ); // DEBUG

    // Simpan kartu
    final List<Map<String, dynamic>> cardsMap =
        _cards.map((card) => card.toJson()).toList();
    await prefs.setString(_prefsKeySavedCards, json.encode(cardsMap));
    // print('DEBUG SAVE: Cards saved: ${json.encode(cardsMap)}'); // DEBUG

    // Simpan next card ID (sudah dilakukan di _addCard, tapi tidak ada salahnya di sini juga)
    await prefs.setInt(
      _prefsKeyNextCardId,
      _nextCardId,
    ); // Simpan ID yang sudah ditingkatkan
    // print('DEBUG SAVE: _nextCardId saved: $_nextCardId'); // DEBUG
  }

  Future<void> _fetchGroups() async {
    // print('DEBUG FETCH GROUPS: Starting _fetchGroups...'); // DEBUG
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_groups.php'));

      // print(
      //   'DEBUG FETCH GROUPS: Response status code: ${response.statusCode}',
      // ); // DEBUG
      // print('DEBUG FETCH GROUPS: Response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          List<String> groups = [];
          for (var group in responseData['data']) {
            groups.add(group['group_code']);
          }
          setState(() {
            _availableGroups = groups;
            // print(
            //   'DEBUG FETCH GROUPS: Groups fetched successfully: $_availableGroups',
            // ); // DEBUG
          });
        } else {
          _showSnackBar('Failed to fetch groups: ${responseData['message']}');
          // print(
          //   'DEBUG FETCH GROUPS: API response failed: ${responseData['message']}',
          // ); // DEBUG
        }
      } else {
        _showSnackBar(
          'Failed to load groups. Status code: ${response.statusCode}',
        );
        // print(
        //   'DEBUG FETCH GROUPS: HTTP error: ${response.statusCode}',
        // ); // DEBUG
      }
    } catch (e) {
      _showSnackBar('Error fetching groups: $e');
      // print('DEBUG FETCH GROUPS: Error fetching groups: $e'); // DEBUG
    }
  }

  Future<void> _fetchCheckersByGroup(
    String groupCode,
    String accountType,
  ) async {
    // print(
    //   'DEBUG FETCH CHECKERS: Calling _fetchCheckersByGroup for group: $groupCode, accountType: $accountType',
    // ); // DEBUG
    final url =
        '$_baseUrl/get_checkers_by_group.php?group_code=$groupCode&account_type=$accountType';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _availableCheckers = List<String>.from(responseData['data']);
            // print(
            //   'DEBUG FETCH CHECKERS: Checkers fetched successfully: $_availableCheckers',
            // ); // DEBUG
          });
          if (_availableCheckers.isEmpty) {
            _showSnackBar(
              'Tidak ada checker ditemukan untuk grup dan tipe akun ini.',
            );
          }
        } else {
          _showSnackBar('Gagal mengambil checker: ${responseData['message']}');
          // print(
          //   'DEBUG FETCH CHECKERS: API response failed: ${responseData['message']}',
          // ); // DEBUG
        }
      } else {
        _showSnackBar(
          'Gagal memuat checker. Kode status: ${response.statusCode}',
        );
        // print(
        //   'DEBUG FETCH CHECKERS: HTTP error: ${response.statusCode}',
        // ); // DEBUG
      }
    } catch (e) {
      _showSnackBar('Error saat mengambil checker: $e');
      // print('DEBUG FETCH CHECKERS: Error fetching checkers: $e'); // DEBUG
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime parsedDate = DateFormat('dd/MM/yy').parse(_selectedDate);

    DateTime initialDateTimeForPicker = parsedDate;
    DateTime firstAllowedDate = DateTime(2000);
    DateTime lastAllowedDate = DateTime(2101);

    if (initialDateTimeForPicker.isBefore(firstAllowedDate)) {
      initialDateTimeForPicker = firstAllowedDate;
    }
    if (initialDateTimeForPicker.isAfter(lastAllowedDate)) {
      initialDateTimeForPicker = lastAllowedDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDateTimeForPicker,
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D2547),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D2547),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd/MM/yy').format(picked);
      });
      await _saveCurrentState(); // Simpan tanggal yang baru dipilih ke SharedPreferences
      _checkIfEntryExistsAndLockChecker(); // Periksa status kunci setelah tanggal berubah
    }
  }

  // Group Dropdown Logic
  void _toggleGroupDropdown() {
    if (_isGroupDropdownOpen) {
      _groupOverlayEntry?.remove();
      _groupOverlayEntry = null;
      setState(() {
        _isGroupDropdownOpen = false;
      });
    } else {
      if (_groupDropdownKey.currentContext == null) return;

      _groupOverlayEntry = _createGroupOverlayEntry();
      Overlay.of(context).insert(_groupOverlayEntry!);
      setState(() {
        _isGroupDropdownOpen = true;
      });
    }
  }

  OverlayEntry _createGroupOverlayEntry() {
    RenderBox renderBox =
        _groupDropdownKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleGroupDropdown,
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
                        color: _darkBlueStrokeColor,
                        width: 1.0,
                      ),
                      boxShadow: _commonBoxShadow,
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children:
                          _availableGroups.map((String value) {
                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _selectedGroup = value;
                                  _selectedUser =
                                      null; // Reset checker when group changes
                                  _toggleGroupDropdown();
                                });
                                if (_loggedInAccountType != null) {
                                  await _fetchCheckersByGroup(
                                    value,
                                    _loggedInAccountType!,
                                  );
                                }
                                await _saveCurrentState(); // Simpan setelah grup berubah
                                _checkIfEntryExistsAndLockChecker(); // Periksa status kunci setelah grup berubah
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
                                        _selectedGroup == value
                                            ? Theme.of(context).primaryColor
                                            : Colors.black,
                                    fontWeight:
                                        _selectedGroup == value
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

  // Checker Dropdown Logic
  void _toggleCheckerDropdown() {
    // Jika checker terkunci, jangan biarkan dropdown terbuka
    if (_isCheckerLocked) {
      _showSnackBar(
        'Checker tidak bisa diubah karena sudah ada data tersimpan untuk tanggal dan grup ini.',
      );
      return;
    }

    if (_isCheckerDropdownOpen) {
      _checkerOverlayEntry?.remove();
      _checkerOverlayEntry = null;
      setState(() {
        _isCheckerDropdownOpen = false;
      });
    } else {
      if (_checkerDropdownKey.currentContext == null) {
        // print(
        //   "DEBUG: _checkerDropdownKey.currentContext is null. Cannot open dropdown.",
        // ); // DEBUG
        return;
      }

      _checkerOverlayEntry = _createCheckerOverlayEntry();
      Overlay.of(context).insert(_checkerOverlayEntry!);
      setState(() {
        _isCheckerDropdownOpen = true;
      });
    }
  }

  OverlayEntry _createCheckerOverlayEntry() {
    RenderBox renderBox =
        _checkerDropdownKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleCheckerDropdown,
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
                        color: _darkBlueStrokeColor,
                        width: 1.0,
                      ),
                      boxShadow: _commonBoxShadow,
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children:
                          _availableCheckers.map((String value) {
                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _selectedUser = value;
                                  _toggleCheckerDropdown();
                                });
                                await _saveCurrentState(); // Simpan setelah pengguna berubah
                                _checkIfEntryExistsAndLockChecker(); // Periksa status kunci setelah checker berubah
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
                                        _selectedUser == value
                                            ? Theme.of(context).primaryColor
                                            : Colors.black,
                                    fontWeight:
                                        _selectedUser == value
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

  // NEW FUNCTION: Memeriksa apakah ada entri yang sudah tersimpan untuk kombinasi saat ini
  Future<void> _checkIfEntryExistsAndLockChecker() async {
    // Hanya periksa jika semua parameter yang diperlukan sudah dipilih
    if (_selectedDate == null ||
        _selectedGroup == null ||
        _selectedUser == null) {
      setState(() {
        _isCheckerLocked =
            false; // Pastikan tidak terkunci jika ada parameter yang belum lengkap
      });
      return;
    }

    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateFormat('dd/MM/yy').parse(_selectedDate));
    final url =
        '$_baseUrl/get_tracking_results.php?entry_date=$formattedDate&group_code=$_selectedGroup&checker_username=$_selectedUser';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          // Checker terkunci jika 'success' true DAN ada 'data' (bukan array kosong)
          _isCheckerLocked =
              responseData['success'] == true &&
              responseData['data'] != null &&
              (responseData['data'] as List).isNotEmpty;
        });
        // print('DEBUG LOCK: Checker lock status for $_selectedDate, $_selectedGroup, $_selectedUser: $_isCheckerLocked');
      } else {
        setState(() {
          _isCheckerLocked =
              false; // Jika ada error API, asumsikan tidak terkunci
        });
        // print('DEBUG LOCK: Error checking entry existence. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isCheckerLocked =
            false; // Jika ada error koneksi, asumsikan tidak terkunci
      });
      // print('DEBUG LOCK: Exception checking entry existence: $e');
    }
  }

  // --- Fungsi _addCard diperbarui untuk menggunakan _nextCardId ---
  void _addCard() async {
    // Jika checker terkunci, dan tidak ada kartu yang sedang diedit, berarti tidak bisa menambah kartu baru dengan checker yang berbeda
    // Ini mungkin tidak perlu jika _isCheckerLocked sudah mencegah perubahan checker
    // Tapi sebagai safety check, bisa ditambahkan.
    // Untuk saat ini, kita biarkan logic _canAddCard yang mengontrol.

    final prefs = await SharedPreferences.getInstance();
    int currentCardId =
        prefs.getInt(_prefsKeyNextCardId) ?? 1; // Ambil ID berikutnya

    setState(() {
      _cards.clear(); // Hapus semua kartu yang ada (karena sistem satu kartu)
      _cards.add(
        CardData(id: currentCardId),
      ); // Tambahkan satu kartu baru dengan ID yang berurutan
      _nextCardId = currentCardId + 1; // Tingkatkan ID untuk kartu berikutnya
    });
    await prefs.setInt(
      _prefsKeyNextCardId,
      _nextCardId,
    ); // Simpan ID yang sudah ditingkatkan
    // print(
    //   'DEBUG ADD CARD: New card added with ID: $currentCardId. Next ID will be: $_nextCardId',
    // ); // DEBUG
    await _saveCurrentState(); // Simpan status kartu yang (sekarang) satu atau kosong
  }

  void _updateCardData(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
    String qty,
    bool hasChanges, // Parameter `hasChanges` tetap ada
  ) {
    setState(() {
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(
          model: model,
          runnoAwal: runnoAwal,
          runnoAkhir: runnoAkhir,
          qty: qty,
          hasChanges: hasChanges, // Menggunakan `hasChanges` dari parameter
        );
      }
    });
    // HAPUS PEMANGGILAN _saveCurrentState() DI SINI.
    // Data akan disimpan saat tombol 'Save' diklik.
  }

  Future<void> _saveCardData(int id) async {
    if (_selectedGroup == null || _selectedUser == null) {
      _showSnackBar('Pilih Grup dan Checker terlebih dahulu!');
      return;
    }
    if (_totalTargetController.text.isEmpty) {
      _showSnackBar('Isi Total Target terlebih dahulu!');
      return;
    }
    if (_cards.isEmpty) {
      _showSnackBar('Tambahkan setidaknya satu kartu untuk disimpan!');
      return;
    }

    final cardToSave = _cards.firstWhere((card) => card.id == id);
    if (!cardToSave.hasChanges) {
      _showSnackBar(
        'Tidak ada perubahan pada card ${cardToSave.id} untuk disimpan!',
      );
      return;
    }

    if (cardToSave.model.isEmpty ||
        cardToSave.runnoAwal.isEmpty ||
        cardToSave.runnoAkhir.isEmpty ||
        cardToSave.qty.isEmpty) {
      _showSnackBar(
        'Harap isi semua kolom Model, Runno Awal, Runno Akhir, dan QTY pada kartu ${cardToSave.id}.',
      );
      return;
    }

    // Validasi QTY lebih ketat
    final int? parsedQty = int.tryParse(cardToSave.qty);
    if (parsedQty == null || parsedQty <= 0) {
      _showSnackBar('QTY harus berupa angka positif yang valid!');
      return;
    }

    List<Map<String, dynamic>> cardsToSave = [
      {
        'model': cardToSave.model,
        'runno_awal': cardToSave.runnoAwal,
        'runno_akhir': cardToSave.runnoAkhir,
        'qty': parsedQty, // Gunakan parsedQty yang sudah divalidasi
      },
    ];

    Map<String, dynamic> postData = {
      'entry_date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yy').parse(_selectedDate)),
      'group_code': _selectedGroup,
      'checker_username': _selectedUser,
      'total_target': int.tryParse(_totalTargetController.text) ?? 0,
      'cards': cardsToSave,
    };

    // print(
    //   'DEBUG: Data yang dikirim ke server: ${json.encode(postData)}',
    // ); // DEBUG

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      // print('DEBUG: Status Code Server: ${response.statusCode}'); // DEBUG
      // print('DEBUG: Response Body Server: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _cards.clear(); // Hapus semua kartu setelah berhasil disimpan
          });
          await _saveCurrentState(); // Simpan status kartu yang kosong ke SharedPreferences
          _showSnackBar('Card ${cardToSave.id} berhasil disimpan ke database!');
          _checkIfEntryExistsAndLockChecker(); // Perbarui status kunci setelah save
        } else {
          _showSnackBar(
            'Gagal menyimpan data card ${cardToSave.id}: ${responseData['message']}',
          );
        }
      } else {
        _showSnackBar(
          'Gagal menyimpan data card ${cardToSave.id}. Kode status: ${response.statusCode}. Respons: ${response.body}', // Tambahkan respons body
        );
      }
    } catch (e) {
      _showSnackBar('Error saat menyimpan data card ${cardToSave.id}: $e');
      // print('DEBUG: Error saat mengirim data: $e'); // DEBUG
    }
  }

  @override
  Widget build(BuildContext context) {
    const BorderSide darkBlueCardBorderSide = BorderSide(
      color: Color(0xFF0D2547),
      width: 1.0,
    );

    final double fabDiameter = 86.0;
    final double boxTopPosition = 190.0;
    final double fabTopOffset = boxTopPosition - (fabDiameter / 2);

    // Tinggi keyboard yang menutupi bagian bawah layar
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // Estimasi tinggi total bottom navigation bar (PillBottomNavigationBar) + padding bawahnya
    // PillBottomNavigationBar diposisikan dengan bottom: 20, dan asumsi tingginya sekitar 70.
    const double bottomNavBarTotalHeight =
        90.0; // 20 (padding) + 70 (estimasi tinggi navbar)

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_isGroupDropdownOpen) _toggleGroupDropdown();
        if (_isCheckerDropdownOpen) _toggleCheckerDropdown();
      },
      child: Stack(
        children: [
          // Input fields yang berada di atas background box
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTopInputFields(),
            ),
          ),
          // Background utama (Box Card) dengan radius dan shadow untuk area kartu
          Positioned.fill(
            top: boxTopPosition,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFDBE6F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                border: Border(
                  top: BorderSide(color: Color(0xFF03112B), width: 9.0),
                ),
                boxShadow: _commonBoxShadow,
              ),
              child: LayoutBuilder(
                // Gunakan LayoutBuilder untuk mendapatkan tinggi Box Card
                builder: (BuildContext context, BoxConstraints constraints) {
                  // constraints.maxHeight adalah tinggi total Box Card (dari boxTopPosition hingga bawah layar)
                  // Kurangi tinggi keyboard dan tinggi navbar dari tinggi yang tersedia untuk scroll
                  final double availableHeightForScroll = max(
                    0.0, // Pastikan tinggi tidak negatif
                    constraints.maxHeight -
                        keyboardHeight -
                        bottomNavBarTotalHeight,
                  );

                  return SizedBox(
                    // Batasi tinggi SingleChildScrollView
                    height: availableHeightForScroll,
                    child: SingleChildScrollView(
                      // Padding atas untuk mengakomodasi FAB yang tumpang tindih
                      // Padding bawah tetap, karena tinggi total sudah diatur oleh SizedBox
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        63.0,
                        16.0,
                        20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_cards.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Belum ada data',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: DynamicCard(
                                cardData: _cards.first,
                                onDataChanged: _updateCardData,
                                onSave: _saveCardData,
                                darkBlueCardBorderSide: darkBlueCardBorderSide,
                                cardBackgroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tombol Add yang melayang dan gabung dengan Box Card
          Positioned(
            top: fabTopOffset,
            left: MediaQuery.of(context).size.width / 2 - (fabDiameter / 2),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox.square(
                dimension: fabDiameter,
                child: FloatingActionButton(
                  // Tombol "Add" hanya aktif jika tidak ada kartu yang sedang ditampilkan (_cards.isEmpty).
                  // Jika ada kartu, onPressed akan menampilkan SnackBar.
                  onPressed: () async {
                    if (_selectedGroup == null || _selectedUser == null) {
                      _showSnackBar('Pilih Grup dan Checker terlebih dahulu!');
                      return;
                    }
                    if (_totalTargetController.text.isEmpty) {
                      _showSnackBar('Isi Total Target terlebih dahulu!');
                      return;
                    }
                    if (_canAddCard) {
                      await _animationController.forward();
                      await _animationController.reverse();
                      _addCard();
                    } else {
                      _showSnackBar(
                        'Hanya boleh ada satu kartu aktif pada satu waktu. Harap simpan atau hapus kartu yang ada terlebih dahulu.',
                      );
                    }
                  },
                  backgroundColor: const Color(0xFF03112B),
                  shape: const CircleBorder(),
                  elevation: 4.0,
                  child: const Icon(Icons.add, color: Colors.white, size: 70),
                  heroTag: 'addCardButton',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Input Field Bagian Atas ---
  Widget _buildTopInputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInputContainer(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputContainer(
                key: _groupDropdownKey, // Tambahkan key untuk dropdown grup
                child: GestureDetector(
                  onTap:
                      _availableGroups.isNotEmpty
                          ? () => _toggleGroupDropdown()
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedGroup ?? 'Pilih Grup',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _selectedGroup == null
                                      ? Colors.grey
                                      : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isGroupDropdownOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.group,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputContainer(
                key: _checkerDropdownKey, // Re-add key for dropdown
                isDisabled: _isCheckerLocked, // NEW: Nonaktifkan jika terkunci
                child: GestureDetector(
                  onTap:
                      (_availableCheckers.isNotEmpty &&
                              !_isCheckerLocked) // NEW: Hanya bisa disentuh jika tidak terkunci
                          ? () => _toggleCheckerDropdown()
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedUser ?? 'Pilih User',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _selectedUser == null ||
                                          _isCheckerLocked // NEW: Ubah warna jika terkunci
                                      ? Colors.grey
                                      : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isCheckerLocked // NEW: Tampilkan ikon kunci jika terkunci
                              ? Icons.lock
                              : (_isCheckerDropdownOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.person),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputContainer(
          child: TextFormField(
            controller: _totalTargetController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: _commonTextFormFieldDecoration(
              hintText: 'Total Target',
              // --- SATU-SATUNYA PERUBAHAN DI SINI ---
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.save,
                  color: Colors.green,
                ), // Ikon save hijau
                onPressed: () async {
                  FocusScope.of(context).unfocus(); // Sembunyikan keyboard
                  await _saveCurrentState(); // Simpan state saat editing selesai
                  _showSnackBar(
                    'Total Target berhasil disimpan!',
                  ); // Tampilkan notifikasi
                },
              ),
              // --- AKHIR PERUBAHAN ---
            ),
            // Tambahkan onEditingComplete untuk menyimpan total target saat keyboard ditutup atau fokus hilang
            onEditingComplete: () async {
              FocusScope.of(context).unfocus(); // Sembunyikan keyboard
              await _saveCurrentState(); // Simpan state saat editing selesai
            },
            onTapOutside: (event) async {
              FocusScope.of(context).unfocus(); // Sembunyikan keyboard
              await _saveCurrentState(); // Simpan state saat fokus hilang
            },
          ),
        ),
      ],
    );
  }
}
