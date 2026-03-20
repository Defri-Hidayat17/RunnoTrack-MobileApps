import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// Import halaman-halaman navigasi (pastikan file ini ada)
import 'package:runnotrack/hasilpage.dart';
import 'package:runnotrack/riwayatpage.dart';
import 'package:runnotrack/profilpage.dart';

// Import PillBottomNavigationBar dari file terpisah yang baru
import 'package:runnotrack/bottomnavigationbar.dart';

// Import CardData dan DynamicCard dari file terpisah yang baru
import 'package:runnotrack/models/card_data.dart';
import 'package:runnotrack/dynamic_card.dart';

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
  String? _loggedInUserId;

  bool _isLoadingUserData = true;

  // 🔥 NEW: Kunci SharedPreferences untuk tipe akun, harus konsisten!
  static const String _prefsKeyAccountType = 'user_account_type';

  // NEW: GlobalKey untuk mengakses _HomeContentPageState
  final GlobalKey<_HomeContentPageState> _homeContentPageKey = GlobalKey();

  // List halaman yang akan ditampilkan di body Scaffold
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadLoggedInUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username');
      // 🔥 UPDATE: Gunakan kunci yang konsisten
      _loggedInAccountType = prefs.getString(_prefsKeyAccountType);
      _profileImageFilename = prefs.getString('photo_url');
      _loggedInUserId = prefs.getString('user_id');

      final String currentUserName = _loggedInUsername ?? 'Pengguna';
      final String currentUserPhotoUrl =
          (_profileImageFilename != null && _profileImageFilename!.isNotEmpty)
              ? _profileImageFilename!
              : '';

      _pages = [
        _HomeContentPage(
          key: _homeContentPageKey,
          loggedInUserId: _loggedInUserId,
        ),
        const Hasilpage(),
        _loggedInUserId != null
            ? Riwayatpage(
              userId: _loggedInUserId!,
              userName: currentUserName,
              userPhotoUrl: currentUserPhotoUrl,
            )
            : const Center(
              child: Text('Error: User ID tidak ditemukan. Mohon login ulang.'),
            ),
        const ProfilPage(),
      ];
      _isLoadingUserData = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _homeContentPageKey.currentState?.refreshHomePageData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _pages[_selectedIndex],
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

  PreferredSizeWidget _buildAppBar() {
    String? fullProfileImageUrl;
    if (_profileImageFilename != null && _profileImageFilename!.isNotEmpty) {
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
                    _onItemTapped(3);
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

/// Konten spesifik untuk Tab "Home" yang akan ditampilkan di dalam HomePage.
class _HomeContentPage extends StatefulWidget {
  final String? loggedInUserId;
  const _HomeContentPage({super.key, this.loggedInUserId});

  @override
  State<_HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<_HomeContentPage>
    with SingleTickerProviderStateMixin {
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
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      key: key,
      padding: padding,
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey[200] : Colors.white,
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
    Widget? prefixIcon,
    bool isEnabled = true,
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
      prefixIcon: prefixIcon,
      enabled: isEnabled,
    );
  }

  // Kunci untuk SharedPreferences
  static const String _prefsKeySelectedDate = 'selectedTrackingDate';
  static const String _prefsKeySelectedGroup = 'selected_group';
  static const String _prefsKeySelectedUser = 'selected_user';
  static const String _prefsKeyTotalTarget = 'total_target';
  static const String _prefsKeySavedCards = 'saved_cards';
  static const String _prefsKeyNextCardId = 'next_card_id';
  static const String _prefsKeyTrackingEntryId = 'tracking_entry_id';
  // 🔥 NEW: Kunci SharedPreferences untuk tipe akun, harus konsisten!
  static const String _prefsKeyAccountType = 'user_account_type';

  String _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
  String? _selectedGroup;
  String? _selectedUser;
  final TextEditingController _totalTargetController = TextEditingController();
  List<CardData> _cards = [];

  List<String> _availableGroups = [];
  List<String> _availableCheckers = [];

  String? _loggedInAccountType;
  int _nextCardId = 1;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Dropdown state variables for group and checker
  final GlobalKey _groupDropdownKey = GlobalKey();
  bool _isGroupDropdownOpen = false;
  OverlayEntry? _groupOverlayEntry;

  final GlobalKey _checkerDropdownKey = GlobalKey();
  bool _isCheckerDropdownOpen = false;
  OverlayEntry? _checkerOverlayEntry;

  // State variable untuk mengunci checker, tanggal, grup
  bool _isTopFieldsLocked = false;
  int? _trackingEntryId;

  String? _initialTotalTargetValue;

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> refreshHomePageData() async {
    await _loadLoggedInUserDataFromPrefs();
    await _fetchGroups();
    await _loadCurrentState();
    await _checkIfEntryExistsAndLockTopFields();
    if (mounted) {
      setState(() {});
    }
  }

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
      await refreshHomePageData();
    });
  }

  @override
  void dispose() {
    _totalTargetController.dispose();
    _animationController.dispose();
    _groupOverlayEntry?.remove();
    _checkerOverlayEntry?.remove();
    super.dispose();
  }

  bool get _canAddCard {
    return _cards.isEmpty && _isTopFieldsLocked && _trackingEntryId != null;
  }

  bool get _isSaveTotalTargetButtonEnabled {
    if (!_isTopFieldsLocked) {
      return _totalTargetController.text.isNotEmpty;
    }
    return _totalTargetController.text != (_initialTotalTargetValue ?? '');
  }

  Future<void> _loadLoggedInUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔥 UPDATE: Gunakan kunci yang konsisten
    _loggedInAccountType = prefs.getString(_prefsKeyAccountType);
  }

  Future<void> _loadCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    final String? savedDateString = prefs.getString(_prefsKeySelectedDate);
    if (savedDateString != null) {
      _selectedDate = savedDateString;
    } else {
      _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
    }

    final String? savedTotalTarget = prefs.getString(_prefsKeyTotalTarget);
    if (savedTotalTarget != null && savedTotalTarget.isNotEmpty) {
      _totalTargetController.text = savedTotalTarget;
      _initialTotalTargetValue = savedTotalTarget;
    } else {
      _initialTotalTargetValue = null;
    }

    final String? cardsJson = prefs.getString(_prefsKeySavedCards);
    if (cardsJson != null && cardsJson != '[]') {
      try {
        final List<dynamic> decodedData = json.decode(cardsJson);
        if (decodedData.isNotEmpty) {
          _cards = [CardData.fromJson(decodedData.first)];
        } else {
          _cards = [];
        }
      } catch (e) {
        _showSnackBar('Error memuat kartu tersimpan: $e');
        await prefs.remove(_prefsKeySavedCards);
      }
    } else {
      _cards = [];
    }

    final String? savedGroup = prefs.getString(_prefsKeySelectedGroup);
    String? tempSelectedGroup;
    if (savedGroup != null && _availableGroups.contains(savedGroup)) {
      tempSelectedGroup = savedGroup;
    } else if (_availableGroups.isNotEmpty) {
      tempSelectedGroup =
          _availableGroups.contains('A') ? 'A' : _availableGroups.first;
    }
    _selectedGroup = tempSelectedGroup;

    if (_selectedGroup != null && _loggedInAccountType != null) {
      await _fetchCheckersByGroup(_selectedGroup!, _loggedInAccountType!);
      final String? savedUser = prefs.getString(_prefsKeySelectedUser);
      if (savedUser != null && _availableCheckers.contains(savedUser)) {
        _selectedUser = savedUser;
      } else {
        _selectedUser = null;
      }
    } else {
      _selectedUser = null;
    }

    _nextCardId = prefs.getInt(_prefsKeyNextCardId) ?? 1;
    _trackingEntryId = prefs.getInt(_prefsKeyTrackingEntryId);
  }

  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_prefsKeySelectedDate, _selectedDate);

    if (_selectedGroup != null) {
      await prefs.setString(_prefsKeySelectedGroup, _selectedGroup!);
    } else {
      await prefs.remove(_prefsKeySelectedGroup);
    }

    if (_selectedUser != null) {
      await prefs.setString(_prefsKeySelectedUser, _selectedUser!);
    } else {
      await prefs.remove(_prefsKeySelectedUser);
    }

    if (_totalTargetController.text.isNotEmpty) {
      await prefs.setString(_prefsKeyTotalTarget, _totalTargetController.text);
    } else {
      await prefs.remove(_prefsKeyTotalTarget);
    }

    final List<Map<String, dynamic>> cardsMap =
        _cards.map((card) => card.toJson()).toList();
    await prefs.setString(_prefsKeySavedCards, json.encode(cardsMap));

    await prefs.setInt(_prefsKeyNextCardId, _nextCardId);
    if (_trackingEntryId != null) {
      await prefs.setInt(_prefsKeyTrackingEntryId, _trackingEntryId!);
    } else {
      await prefs.remove(_prefsKeyTrackingEntryId);
    }
  }

  Future<void> _fetchGroups() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_groups.php'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          List<String> groups = [];
          for (var group in responseData['data']) {
            groups.add(group['group_code']);
          }
          setState(() {
            _availableGroups = groups;
          });
        } else {
          _showSnackBar('Failed to fetch groups: ${responseData['message']}');
        }
      } else {
        _showSnackBar(
          'Failed to load groups. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error fetching groups: $e');
    }
  }

  Future<void> _fetchCheckersByGroup(
    String groupCode,
    String accountType,
  ) async {
    final url =
        '$_baseUrl/get_checkers_by_group.php?group_code=$groupCode&account_type=$accountType';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _availableCheckers = List<String>.from(responseData['data']);
          });
          if (_availableCheckers.isEmpty) {
            _showSnackBar(
              'Tidak ada checker ditemukan untuk grup dan tipe akun ini.',
            );
          }
        } else {
          _showSnackBar('Gagal mengambil checker: ${responseData['message']}');
        }
      } else {
        _showSnackBar(
          'Gagal memuat checker. Kode status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat mengambil checker: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isTopFieldsLocked) return;

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
      await _saveCurrentState();
      await _checkIfEntryExistsAndLockTopFields();
    }
  }

  void _toggleGroupDropdown() {
    if (_isTopFieldsLocked) return;
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
                                  _selectedUser = null;
                                  _toggleGroupDropdown();
                                });
                                if (_loggedInAccountType != null) {
                                  await _fetchCheckersByGroup(
                                    value,
                                    _loggedInAccountType!,
                                  );
                                }
                                await _saveCurrentState();
                                await _checkIfEntryExistsAndLockTopFields();
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

  void _toggleCheckerDropdown() {
    if (_isTopFieldsLocked) return;
    if (_isCheckerDropdownOpen) {
      _checkerOverlayEntry?.remove();
      _checkerOverlayEntry = null;
      setState(() {
        _isCheckerDropdownOpen = false;
      });
    } else {
      if (_checkerDropdownKey.currentContext == null) return;

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
                                await _saveCurrentState();
                                await _checkIfEntryExistsAndLockTopFields();
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

  Future<void> _checkIfEntryExistsAndLockTopFields() async {
    if (widget.loggedInUserId == null) {
      setState(() {
        _isTopFieldsLocked = false;
        _trackingEntryId = null;
        _totalTargetController.clear();
        _initialTotalTargetValue = null;
      });
      _showSnackBar('Error: User ID tidak ditemukan untuk memeriksa entri.');
      return;
    }

    if (_selectedDate == null ||
        _selectedGroup == null ||
        _selectedUser == null) {
      setState(() {
        _isTopFieldsLocked = false;
        _trackingEntryId = null;
        _totalTargetController.clear();
        _initialTotalTargetValue = null;
      });
      return;
    }

    final formattedDate = DateFormat('dd/MM/yy').parse(_selectedDate);

    final url =
        '$_baseUrl/get_tracking_results.php?entry_date=${DateFormat('yyyy-MM-dd').format(formattedDate)}&group_code=$_selectedGroup&checker_username=$_selectedUser&user_id=${widget.loggedInUserId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          if (responseData['success'] == true &&
              responseData['data'] != null &&
              (responseData['data'] as List).isNotEmpty) {
            _isTopFieldsLocked = true;
            _trackingEntryId = responseData['data'][0]['tracking_entry_id'];
            _totalTargetController.text =
                responseData['data'][0]['total_target'].toString();
            _initialTotalTargetValue = _totalTargetController.text;
          } else {
            _isTopFieldsLocked = false;
            _trackingEntryId = null;
            _totalTargetController.clear();
            _initialTotalTargetValue = null;
          }
        });
        await _saveCurrentState();
      } else {
        setState(() {
          _isTopFieldsLocked = false;
          _trackingEntryId = null;
          _initialTotalTargetValue = null;
        });
      }
    } catch (e) {
      setState(() {
        _isTopFieldsLocked = false;
        _trackingEntryId = null;
        _initialTotalTargetValue = null;
      });
    }
  }

  Future<void> _saveTopFieldsToDatabase() async {
    FocusScope.of(context).unfocus();

    if (widget.loggedInUserId == null) {
      _showSnackBar('Error: User ID tidak ditemukan. Mohon login ulang.');
      return;
    }

    if (_selectedGroup == null || _selectedUser == null) {
      _showSnackBar('Pilih Grup dan Checker terlebih dahulu!');
      return;
    }
    if (_totalTargetController.text.isEmpty) {
      _showSnackBar('Isi Total Target terlebih dahulu!');
      return;
    }

    final int? parsedTotalTarget = int.tryParse(_totalTargetController.text);
    if (parsedTotalTarget == null || parsedTotalTarget < 0) {
      _showSnackBar('Total Target harus berupa angka positif yang valid!');
      return;
    }

    Map<String, dynamic> postData = {
      'entry_date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yy').parse(_selectedDate)),
      'group_code': _selectedGroup,
      'checker_username': _selectedUser,
      'total_target': parsedTotalTarget,
      'user_id': widget.loggedInUserId,
    };

    if (_trackingEntryId != null) {
      postData['tracking_entry_id'] = _trackingEntryId;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_tracking_entry.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _trackingEntryId = responseData['tracking_entry_id'];
            _isTopFieldsLocked = true;
            _initialTotalTargetValue = _totalTargetController.text;
          });
          await _saveCurrentState();
          _showSnackBar('Data utama berhasil disimpan!');
        } else {
          _showSnackBar(
            'Gagal menyimpan data utama: ${responseData['message']}',
          );
        }
      } else {
        _showSnackBar(
          'Gagal menyimpan data utama. Kode status: ${response.statusCode}. Respons: ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat menyimpan data utama: $e');
    }
  }

  void _addCard() async {
    if (!_isTopFieldsLocked || _trackingEntryId == null) {
      _showSnackBar(
        'Harap simpan data Tanggal, Grup, Checker, dan Total Target terlebih dahulu!',
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    int currentCardId = prefs.getInt(_prefsKeyNextCardId) ?? 1;

    setState(() {
      _cards.clear();
      _cards.add(CardData(id: currentCardId));
      _nextCardId = currentCardId + 1;
    });
    await prefs.setInt(_prefsKeyNextCardId, _nextCardId);
    await _saveCurrentState();
  }

  void _updateCardData(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
    String qty,
    bool hasChanges,
  ) {
    setState(() {
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(
          model: model,
          runnoAwal: runnoAwal,
          runnoAkhir: runnoAkhir,
          qty: qty,
          hasChanges: hasChanges,
        );
      }
    });
  }

  Future<void> _saveCardData(int id) async {
    if (_trackingEntryId == null) {
      _showSnackBar(
        'ID Entri Tracking tidak ditemukan. Harap simpan data utama terlebih dahulu.',
      );
      return;
    }
    if (_cards.isEmpty) {
      _showSnackBar('Tidak ada kartu untuk disimpan!');
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

    final int? parsedQty = int.tryParse(cardToSave.qty);
    if (parsedQty == null || parsedQty <= 0) {
      _showSnackBar('QTY harus berupa angka positif yang valid!');
      return;
    }

    Map<String, dynamic> cardData = {
      'tracking_entry_id': _trackingEntryId,
      'model': cardToSave.model,
      'runno_awal': cardToSave.runnoAwal,
      'runno_akhir': cardToSave.runnoAkhir,
      'qty': parsedQty,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_card_details.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cardData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          setState(() {
            _cards.clear();
          });
          await _saveCurrentState();
          _showSnackBar('Card ${cardToSave.id} berhasil disimpan ke database!');
        } else {
          _showSnackBar(
            'Gagal menyimpan data card ${cardToSave.id}: ${responseData['message']}',
          );
        }
      } else {
        _showSnackBar(
          'Gagal menyimpan data card ${cardToSave.id}. Kode status: ${response.statusCode}. Respons: ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat menyimpan data card ${cardToSave.id}: $e');
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

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    const double bottomNavBarTotalHeight = 90.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_isGroupDropdownOpen) _toggleGroupDropdown();
        if (_isCheckerDropdownOpen) _toggleCheckerDropdown();
      },
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTopInputFields(),
            ),
          ),
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
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double availableHeightForScroll = max(
                    0.0,
                    constraints.maxHeight -
                        keyboardHeight -
                        bottomNavBarTotalHeight,
                  );

                  return SizedBox(
                    height: availableHeightForScroll,
                    child: SingleChildScrollView(
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
          Positioned(
            top: fabTopOffset,
            left: MediaQuery.of(context).size.width / 2 - (fabDiameter / 2),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox.square(
                dimension: fabDiameter,
                child: FloatingActionButton(
                  onPressed:
                      _canAddCard
                          ? () async {
                            await _animationController.forward();
                            await _animationController.reverse();
                            _addCard();
                          }
                          : () {
                            if (!_isTopFieldsLocked) {
                              _showSnackBar(
                                'Harap simpan data Tanggal, Grup, Checker, dan Total Target terlebih dahulu!',
                              );
                            } else if (_cards.isNotEmpty) {
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

  Widget _buildTopInputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 10,
              child: _buildInputContainer(
                isDisabled: _isTopFieldsLocked,
                child: GestureDetector(
                  onTap: _isTopFieldsLocked ? null : () => _selectDate(context),
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
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _isTopFieldsLocked
                                      ? Colors.grey
                                      : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color:
                              _isTopFieldsLocked
                                  ? Colors.grey[400]
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 10,
              child: _buildInputContainer(
                key: _groupDropdownKey,
                isDisabled: _isTopFieldsLocked,
                child: GestureDetector(
                  onTap:
                      (_availableGroups.isNotEmpty && !_isTopFieldsLocked)
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
                                  _selectedGroup == null || _isTopFieldsLocked
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
                          color:
                              _isTopFieldsLocked
                                  ? Colors.grey[400]
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 10,
              child: _buildInputContainer(
                key: _checkerDropdownKey,
                isDisabled: _isTopFieldsLocked,
                child: GestureDetector(
                  onTap:
                      (_availableCheckers.isNotEmpty && !_isTopFieldsLocked)
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
                                  _selectedUser == null || _isTopFieldsLocked
                                      ? Colors.grey
                                      : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isTopFieldsLocked
                              ? Icons.lock
                              : (_isCheckerDropdownOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.person),
                          color:
                              _isTopFieldsLocked
                                  ? Colors.grey[400]
                                  : Colors.grey,
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
        Row(
          children: [
            Expanded(
              flex: 21,
              child: _buildInputContainer(
                child: TextFormField(
                  controller: _totalTargetController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  enabled: true,
                  decoration: _commonTextFormFieldDecoration(
                    hintText: 'Total Target',
                  ),
                  onChanged: (value) {
                    setState(() {
                      // _isSaveTotalTargetButtonEnabled akan dihitung ulang
                    });
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
            const Spacer(flex: 1),
            Expanded(
              flex: 10,
              child: ElevatedButton(
                onPressed:
                    _isSaveTotalTargetButtonEnabled
                        ? _saveTopFieldsToDatabase
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaveTotalTargetButtonEnabled
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                  shadowColor: Colors.grey,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
