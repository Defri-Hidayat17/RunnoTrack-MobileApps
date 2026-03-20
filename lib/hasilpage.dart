// lib/hasilpage.dart (FINAL VERSION with PageView.builder for performance)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

// Import model dan widget yang benar
import 'package:runnotrack/models/card_data.dart'; // Model data
import 'package:runnotrack/hasilpage_card_widget.dart'; // Widget kartu baru untuk Hasilpage

// Definisi base URL untuk API Anda
const String _baseUrl =
    'http://192.168.1.10/runnotrack_api'; // SESUAIKAN DENGAN IP SERVER ANDA

class Hasilpage extends StatefulWidget {
  const Hasilpage({super.key});

  @override
  State<Hasilpage> createState() => _HasilpageState();
}

class _HasilpageState extends State<Hasilpage> {
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

  // --- Konstanta untuk Layout Tombol dan Status ---
  static const double _kActionElementHeight =
      44.0; // Tinggi standar untuk tombol dan status
  static const double _kButtonHorizontalPadding =
      15.0; // Padding horizontal standar untuk tombol
  static const double _kSpacing = 8.0; // Spasi standar antar elemen
  // --- Akhir Konstanta ---

  Widget _buildSummaryFloatingLabelBox({
    required String label,
    required String value,
    Color valueColor = Colors.black87,
    FontWeight fontWeight = FontWeight.normal,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _darkBlueStrokeColor, width: 1.0),
        boxShadow: _commonBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                  fontWeight: fontWeight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: iconColor ?? valueColor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan data saja (read-only)
  Widget _buildDisplayContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _darkBlueStrokeColor, width: 1.0),
        boxShadow: _commonBoxShadow,
      ),
      child: child,
    );
  }
  // --- Akhir Styling Umum ---

  // Kunci SharedPreferences (harus sama dengan di HomePage)
  static const String _prefsKeySelectedDate = 'selectedTrackingDate';
  static const String _prefsKeySelectedGroup = 'selected_group';
  static const String _prefsKeySelectedUser = 'selected_user';
  static const String _prefsKeyTotalTarget = 'total_target';

  // Kunci SharedPreferences BARU untuk status konfirmasi sementara
  static const String _prefsKeyLastConfirmedStatus = 'lastConfirmedStatus';
  static const String _prefsKeyLastConfirmedDate = 'lastConfirmedDate';
  static const String _prefsKeyLastConfirmedGroup = 'lastConfirmedGroup';
  static const String _prefsKeyLastConfirmedChecker = 'lastConfirmedChecker';

  String _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
  String? _selectedGroup;
  String? _selectedChecker;
  String? _loggedInAccountType;
  String? _loggedInUserId; // 🔥 NEW: Variabel untuk menyimpan user_id

  List<CardData> _resultCards = [];
  bool _isLoading = false;

  // Global summary values
  int _totalTarget = 0;
  int _totalActual = 0;
  int _totalDifference = 0;
  double _overallEfficiency = 0.0;
  bool _isEntryConfirmed = false;

  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  ); // Untuk PageView

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(); // Initial load
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(); // Re-load data if dependencies (like SharedPreferences) change
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // print('DEBUG Hasilpage: _refreshData called.');

    final prefs = await SharedPreferences.getInstance();

    // --- LOGIKA BARU: Cek status konfirmasi sementara ---
    bool lastConfirmedStatus =
        prefs.getBool(_prefsKeyLastConfirmedStatus) ?? false;
    String? lastConfirmedDate = prefs.getString(_prefsKeyLastConfirmedDate);
    String? lastConfirmedGroup = prefs.getString(_prefsKeyLastConfirmedGroup);
    String? lastConfirmedChecker = prefs.getString(
      _prefsKeyLastConfirmedChecker,
    );

    if (lastConfirmedStatus &&
        lastConfirmedDate != null &&
        lastConfirmedGroup != null &&
        lastConfirmedChecker != null) {
      // Jika ada status konfirmasi sementara, tampilkan itu dan kosongkan data
      if (mounted) {
        setState(() {
          _selectedDate = lastConfirmedDate;
          _selectedGroup = lastConfirmedGroup;
          _selectedChecker = lastConfirmedChecker;
          _loggedInAccountType = prefs.getString(
            'accountType',
          ); // Tetap ambil dari prefs
          _loggedInUserId = prefs.getString('user_id'); // 🔥 NEW: Ambil user_id
          _totalTarget = 0; // Kosongkan
          _resultCards = []; // Kosongkan
          _totalActual = 0; // Kosongkan
          _totalDifference = 0; // Kosongkan
          _overallEfficiency = 0.0; // Kosongkan
          _isEntryConfirmed = true; // Set ke sukses
        });
      }
      // Hapus status konfirmasi sementara agar tidak tampil lagi di refresh berikutnya
      await prefs.remove(_prefsKeyLastConfirmedStatus);
      await prefs.remove(_prefsKeyLastConfirmedDate);
      await prefs.remove(_prefsKeyLastConfirmedGroup);
      await prefs.remove(_prefsKeyLastConfirmedChecker);
      return; // Selesai, jangan lanjutkan ke pengambilan data API
    }
    // --- AKHIR LOGIKA BARU ---

    // --- LOGIKA LAMA (setelah pemeriksaan status sementara) ---
    final String newSelectedDate =
        prefs.getString(_prefsKeySelectedDate) ??
        DateFormat('dd/MM/yy').format(DateTime.now());
    final String? newSelectedGroup = prefs.getString(_prefsKeySelectedGroup);
    final String? newSelectedChecker = prefs.getString(_prefsKeySelectedUser);
    final String? newLoggedInAccountType = prefs.getString('accountType');
    final String? newLoggedInUserId = prefs.getString(
      'user_id',
    ); // 🔥 NEW: Ambil user_id dari SharedPreferences
    final int newTotalTarget =
        int.tryParse(prefs.getString(_prefsKeyTotalTarget) ?? '0') ?? 0;

    if (mounted) {
      setState(() {
        _selectedDate = newSelectedDate;
        _selectedGroup = newSelectedGroup;
        _selectedChecker = newSelectedChecker;
        _loggedInAccountType = newLoggedInAccountType;
        _loggedInUserId = newLoggedInUserId; // 🔥 NEW: Set user_id
        _totalTarget = newTotalTarget;
      });
    }

    // 🔥 MODIFIED: Tambahkan _loggedInUserId != null sebagai kondisi
    if (_selectedGroup != null &&
        _selectedChecker != null &&
        _loggedInUserId != null) {
      await _fetchTrackingResults(
        date: _selectedDate,
        group: _selectedGroup!,
        checker: _selectedChecker!,
        target: _totalTarget,
        userId: _loggedInUserId!, // 🔥 NEW: Teruskan userId
      );
    } else {
      // print(
      //   'DEBUG Hasilpage: Tidak mengambil hasil karena grup atau checker null.',
      // );
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference = _totalActual - _totalTarget;
          _overallEfficiency =
              _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
          _isEntryConfirmed = false;
        });
      }
    }
  }

  Future<void> _fetchTrackingResults({
    required String date,
    required String group,
    required String checker,
    required int target,
    required String userId, // 🔥 NEW: Tambahkan parameter userId
  }) async {
    // print(
    //   'DEBUG Hasilpage: _fetchTrackingResults called with date=$date, group=$group, checker=$checker, target=$target',
    // );
    // 🔥 MODIFIED: Tambahkan userId ke kondisi validasi null
    if (group == null || checker == null || userId == null) {
      // print(
      //   'DEBUG Hasilpage: Skipping API call due to null parameters: Group=$group, Checker=$checker, UserId=$userId',
      // );
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference = _totalActual - target;
          _overallEfficiency = target > 0 ? (_totalActual / target) * 100 : 0.0;
          _isEntryConfirmed =
              false; // Jika parameter null, anggap belum dikonfirmasi
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateFormat('dd/MM/yy').parse(date));
    // 🔥 MODIFIED: Tambahkan user_id ke URL
    final url =
        '$_baseUrl/get_tracking_results.php?entry_date=$formattedDate&group_code=$group&checker_username=$checker&user_id=$userId';
    // print('DEBUG Hasilpage: Attempting to fetch from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      // print('DEBUG Hasilpage: Response Status Code: ${response.statusCode}');
      // print('DEBUG Hasilpage: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // print('DEBUG Hasilpage: Parsed JSON: $responseData');
        if (responseData['success']) {
          List<CardData> fetchedCards = [];
          int currentTotalActual = 0;
          bool entryConfirmedStatus = false; // Default ke false

          if (responseData['data'] != null &&
              responseData['data'] is List &&
              responseData['data'].isNotEmpty) {
            var entryItem = responseData['data'][0];
            // Ambil status konfirmasi dari API
            entryConfirmedStatus =
                int.tryParse(entryItem['is_confirmed'].toString()) == 1;

            if (entryItem['cards'] != null && entryItem['cards'] is List) {
              for (int i = 0; i < entryItem['cards'].length; i++) {
                var cardJson = entryItem['cards'][i];
                int actualQtyInt =
                    int.tryParse(cardJson['qty'].toString()) ?? 0;
                fetchedCards.add(
                  CardData(
                    id: i + 1, // Local UI ID
                    cardDetailId: int.tryParse(
                      cardJson['id'].toString(),
                    ), // <--- PENTING: Ambil card_detail_id dari JSON
                    model: cardJson['model'] ?? '',
                    runnoAwal: cardJson['runno_awal'] ?? '',
                    runnoAkhir: cardJson['runno_akhir'] ?? '',
                    qty: actualQtyInt.toString(),
                    hasChanges: false,
                    shouldResetEditMode:
                        false, // BARU: Pastikan ini false saat memuat dari server
                  ),
                );
                currentTotalActual += actualQtyInt;
              }
            }
          }
          // print(
          //   'DEBUG Hasilpage: Data successfully parsed. Cards count: ${fetchedCards.length}',
          // );

          if (mounted) {
            setState(() {
              _resultCards = fetchedCards;
              _totalActual = currentTotalActual;
              _totalDifference =
                  currentTotalActual -
                  _totalTarget; // Gunakan _totalTarget dari state Hasilpage
              _overallEfficiency =
                  _totalTarget > 0
                      ? (currentTotalActual / _totalTarget) * 100
                      : 0.0;
              _isEntryConfirmed =
                  entryConfirmedStatus; // Update status konfirmasi dari API
            });
          }
        } else {
          // print(
          //   'DEBUG Hasilpage: API returned success: false. Message: ${responseData['message']}',
          // );
          _showSnackBar('Tidak ada data hasil untuk kriteria yang dipilih.');
          if (mounted) {
            setState(() {
              _resultCards = [];
              _totalActual = 0;
              _totalDifference = _totalActual - _totalTarget;
              _overallEfficiency =
                  _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
              _isEntryConfirmed =
                  false; // Jika tidak ada data, anggap belum dikonfirmasi
            });
          }
        }
      } else {
        // print(
        //   'DEBUG Hasilpage: HTTP error. Status: ${response.statusCode}, Body: ${response.body}',
        // );
        _showSnackBar(
          'Failed to load results. Status code: ${response.statusCode}.',
        );
        if (mounted) {
          setState(() {
            _resultCards = [];
            _totalActual = 0;
            _totalDifference = _totalActual - _totalTarget;
            _overallEfficiency =
                _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
            _isEntryConfirmed = false; // Jika error, anggap belum dikonfirmasi
          });
        }
      }
    } catch (e) {
      // print('DEBUG Hasilpage: Error during API call or JSON parsing: $e');
      _showSnackBar('Error fetching results: $e');
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference = _totalActual - _totalTarget;
          _overallEfficiency =
              _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
          _isEntryConfirmed = false; // Jika error, anggap belum dikonfirmasi
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NEW: Callback for when a card's data changes in HasilpageCardWidget
  void _onCardDataChanged(int localId, CardData updatedCardData) {
    if (mounted) {
      final index = _resultCards.indexWhere((card) => card.id == localId);
      if (index != -1) {
        if (_resultCards[index] != updatedCardData) {
          setState(() {
            _resultCards[index] = updatedCardData.copyWith(
              hasChanges: true, // Mark as changed
              shouldResetEditMode:
                  updatedCardData.shouldResetEditMode ||
                  _resultCards[index].shouldResetEditMode,
            );
            _recalculateSummaryValues(); // Recalculate summaries immediately
          });
        }
      }
    }
  }

  void _recalculateSummaryValues() {
    int currentTotalActual = 0;
    for (var card in _resultCards) {
      currentTotalActual += int.tryParse(card.qty) ?? 0;
    }
    _totalActual = currentTotalActual;
    _totalDifference = _totalActual - _totalTarget;
    _overallEfficiency =
        _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
  }

  // NEW: Callback for when the "Save" button in HasilpageCardWidget is pressed
  Future<void> _onSaveUpdatedCard(CardData cardToSave) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa diubah.');
      return;
    }
    if (_selectedGroup == null || _selectedChecker == null) {
      _showSnackBar('Grup atau Checker tidak valid.');
      return;
    }

    // Ensure the cardToSave has valid data
    if (cardToSave.model.isEmpty ||
        cardToSave.runnoAwal.isEmpty ||
        cardToSave.runnoAkhir.isEmpty ||
        cardToSave.qty.isEmpty) {
      _showSnackBar('Harap isi semua kolom pada kartu ini.');
      return;
    }

    final int? parsedQty = int.tryParse(cardToSave.qty);
    if (parsedQty == null || parsedQty < 0) {
      _showSnackBar('QTY harus berupa angka yang valid!');
      return;
    }

    // Prepare all cards for sending to the backend
    List<Map<String, dynamic>> cardsToSend =
        _resultCards.map((card) {
          if (card.id == cardToSave.id) {
            return cardToSave.copyWith(hasChanges: false).toJson();
          }
          return card.toJson();
        }).toList();

    Map<String, dynamic> postData = {
      'entry_date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yy').parse(_selectedDate)),
      'group_code': _selectedGroup,
      'checker_username': _selectedChecker,
      'total_target': _totalTarget,
      'cards': cardsToSend,
    };

    print('DEBUG Hasilpage: Data to update/save: ${json.encode(postData)}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      print(
        'DEBUG Hasilpage: Update/Save Card Response Status Code: ${response.statusCode}',
      );
      print(
        'DEBUG Hasilpage: Update/Save Card Response Body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar('Kartu berhasil diperbarui!');

          if (mounted) {
            setState(() {
              final index = _resultCards.indexWhere(
                (card) => card.id == cardToSave.id,
              );
              if (index != -1) {
                _resultCards[index] = cardToSave.copyWith(
                  hasChanges: false,
                  shouldResetEditMode: true,
                );
              }
            });
          }
          // 🔥 MODIFIED: Panggil _fetchTrackingResults dengan userId
          if (_selectedGroup != null &&
              _selectedChecker != null &&
              _loggedInUserId != null) {
            _fetchTrackingResults(
              date: _selectedDate,
              group: _selectedGroup!,
              checker: _selectedChecker!,
              target: _totalTarget,
              userId: _loggedInUserId!, // 🔥 NEW: Teruskan userId
            );
          }
        } else {
          _showSnackBar('Gagal memperbarui kartu: ${responseData['message']}');
        }
      } else {
        _showSnackBar(
          'Gagal memperbarui kartu. Kode status: ${response.statusCode}. Respons: ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat memperbarui kartu: $e');
    }
  }

  // NEW: Callback for when the "Delete" button in HasilpageCardWidget is pressed
  Future<void> _onDeleteCard(int? cardDetailId) async {
    // Ubah tipe menjadi int?
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa dihapus.');
      return;
    }
    if (_selectedGroup == null || _selectedChecker == null) {
      _showSnackBar('Grup atau Checker tidak valid.');
      return;
    }
    if (cardDetailId == null) {
      // Cek null di sini
      _showSnackBar('ID detail kartu tidak valid untuk dihapus.');
      return;
    }

    Map<String, dynamic> postData = {'card_detail_id': cardDetailId};

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_tracking_card.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar('Kartu berhasil dihapus!');
          // 🔥 MODIFIED: Panggil _fetchTrackingResults dengan userId
          if (mounted &&
              _selectedGroup != null &&
              _selectedChecker != null &&
              _loggedInUserId != null) {
            _fetchTrackingResults(
              date: _selectedDate,
              group: _selectedGroup!,
              checker: _selectedChecker!,
              target: _totalTarget,
              userId: _loggedInUserId!, // 🔥 NEW: Teruskan userId
            );
          }
        } else {
          _showSnackBar('Gagal menghapus kartu: ${responseData['message']}');
        }
      } else {
        _showSnackBar(
          'Gagal menghapus kartu. Kode status: ${response.statusCode}. Respons: ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat menghapus kartu: $e');
    }
  }

  Future<void> _confirmTrackingEntry() async {
    // print('DEBUG Hasilpage: _confirmTrackingEntry called.');
    if (_selectedGroup == null || _selectedChecker == null) {
      _showSnackBar('Grup atau Checker tidak valid.');
      return;
    }
    if (_resultCards.isEmpty) {
      _showSnackBar('Tidak ada data untuk dikonfirmasi.');
      return;
    }
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi sebelumnya.');
      return;
    }

    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateFormat('dd/MM/yy').parse(_selectedDate));

    Map<String, dynamic> postData = {
      'entry_date': formattedDate,
      'group_code': _selectedGroup,
      'checker_username': _selectedChecker,
      'user_id': _loggedInUserId, // 🔥 NEW: Tambahkan user_id ke postData
    };
    // print(
    //   'DEBUG Hasilpage: _confirmTrackingEntry POST data: ${json.encode(postData)}',
    // );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/confirm_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );
      // print(
      //   'DEBUG Hasilpage: _confirmTrackingEntry Response Status Code: ${response.statusCode}',
      // );
      // print(
      //   'DEBUG Hasilpage: _confirmTrackingEntry Response Body: ${response.body}',
      // );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar('Data berhasil dikonfirmasi!');
          // print('DEBUG Hasilpage: _confirmTrackingEntry success.');

          final prefs = await SharedPreferences.getInstance();
          // --- BARU: Simpan status konfirmasi sementara dan detail entri ---
          await prefs.setBool(_prefsKeyLastConfirmedStatus, true);
          await prefs.setString(_prefsKeyLastConfirmedDate, _selectedDate);
          await prefs.setString(_prefsKeyLastConfirmedGroup, _selectedGroup!);
          await prefs.setString(
            _prefsKeyLastConfirmedChecker,
            _selectedChecker!,
          );

          // --- Hapus data dari SharedPreferences utama ---
          await prefs.remove(_prefsKeySelectedDate);
          await prefs.remove(_prefsKeySelectedGroup);
          await prefs.remove(_prefsKeySelectedUser);
          await prefs.remove(_prefsKeyTotalTarget);

          // --- Panggil _refreshData untuk memicu tampilan status "Sukses" dengan data kosong ---
          await _refreshData();
        } else {
          _showSnackBar('Gagal konfirmasi data: ${responseData['message']}');
        }
      } else {
        _showSnackBar(
          'Gagal konfirmasi data. Kode status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat konfirmasi data: $e');
    }
  }

  Future<void> _sendToWhatsApp() async {
    // print('DEBUG Hasilpage: _sendToWhatsApp called.');
    final String message =
        "Halo, berikut data tracking:\n"
        "Tanggal: $_selectedDate\n"
        "Grup: ${_selectedGroup ?? 'N/A'}\n"
        "Checker: ${_selectedChecker ?? 'N/A'}\n"
        "---------------------------\n"
        "Total Target: $_totalTarget\n"
        "Total Actual: $_totalActual\n"
        "Total Difference: $_totalDifference\n"
        "Overall Efficiency: ${_overallEfficiency.toStringAsFixed(2)}%\n"
        "Status Konfirmasi: ${_isEntryConfirmed ? 'Sukses' : 'Pending'}"; // Di sini juga ganti

    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?text=${Uri.encodeComponent(message)}",
    );
    // print('DEBUG Hasilpage: WhatsApp URL: $whatsappUrl');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
      // print('DEBUG Hasilpage: Launched WhatsApp.');
    } else {
      _showSnackBar(
        'Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstal.',
      );
      // print('DEBUG Hasilpage: Failed to launch WhatsApp.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      // print('DEBUG Hasilpage: SnackBar shown: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    const BorderSide darkBlueCardBorderSide = BorderSide(
      color: Color(0xFF0D2547),
      width: 1.0,
    );

    Color confirmationColor =
        _isEntryConfirmed
            ? Colors.green
            : const Color.fromARGB(255, 255, 84, 84);
    String confirmationText = _isEntryConfirmed ? 'Sukses' : 'Pending';

    const double bottomNavBarTotalHeight = 90.0;

    return
    // HAPUS GestureDetector ini
    // GestureDetector(
    //   onTap: () {
    //     FocusScope.of(context).unfocus();
    //   },
    //   child:
    Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTopDisplayFields(),
              const SizedBox(height: 16),
              _buildSummarySection(),
            ],
          ),
        ),

        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFDBE6F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              border: Border(
                top: BorderSide(color: Color(0xFF03112B), width: 9.0),
              ),
              boxShadow: _commonBoxShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Entry Status (Kiri)
                      Expanded(
                        child: Container(
                          height: _kActionElementHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: _kButtonHorizontalPadding,
                          ),
                          decoration: BoxDecoration(
                            color: confirmationColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Status: $confirmationText',
                            style: TextStyle(
                              color: confirmationColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      const SizedBox(width: _kSpacing),
                      // Refresh Button (Tengah)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(
                            _kActionElementHeight,
                            _kActionElementHeight,
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: _kSpacing),
                      // --- PERUBAHAN DI SINI: Logika tombol Konfirmasi/WhatsApp ---
                      Expanded(
                        child:
                            !_isEntryConfirmed && _resultCards.isNotEmpty
                                ? ElevatedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () => _confirmTrackingEntry(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2547),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: _kButtonHorizontalPadding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size(
                                      0,
                                      _kActionElementHeight,
                                    ),
                                  ),
                                  child: const Text(
                                    'Konfirmasi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                      // --- AKHIR PERUBAHAN ---
                    ],
                  ),
                  const SizedBox(height: 10),

                  _isLoading
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                      : _resultCards.isEmpty
                      ? Center(
                        // Menggunakan Center untuk pesan "Tidak ada data"
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _isEntryConfirmed && _selectedGroup != null
                                ? 'Entri untuk $_selectedGroup pada $_selectedDate telah berhasil dikonfirmasi.'
                                : 'Tidak ada data hasil untuk kriteria yang dipilih.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : SizedBox(
                        height: 200,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _resultCards.length,
                          itemBuilder: (context, index) {
                            final card = _resultCards[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: HasilpageCardWidget(
                                key: ValueKey(card.id),
                                cardData: card,
                                darkBlueCardBorderSide: darkBlueCardBorderSide,
                                cardBackgroundColor: Colors.white,
                                readOnly: _isEntryConfirmed,
                                onCardDataChanged: _onCardDataChanged,
                                onSaveUpdatedCard: _onSaveUpdatedCard,
                                onDeleteCard: _onDeleteCard,
                              ),
                            );
                          },
                        ),
                      ),
                  SizedBox(height: bottomNavBarTotalHeight),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDisplayFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDisplayContainer(
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
            const SizedBox(width: 10),
            Expanded(
              child: _buildDisplayContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedGroup ?? 'Grup',
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
                    const Icon(Icons.group, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDisplayContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedChecker ?? 'Checker',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedChecker == null
                                  ? Colors.grey
                                  : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.person, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryFloatingLabelBox(
                label: 'Target',
                value: _totalTarget.toString(),
                valueColor: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryFloatingLabelBox(
                label: 'Total QTY',
                value: _totalActual.toString(),
                valueColor: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryFloatingLabelBox(
                label: 'Difference',
                value:
                    _totalDifference > 0
                        ? '+${_totalDifference.toString()}'
                        : _totalDifference.toString(),
                valueColor:
                    _totalDifference < 0
                        ? Colors.red
                        : (_totalDifference > 0 ? Colors.green : Colors.blue),
                fontWeight: FontWeight.bold,
                icon:
                    _totalDifference < 0
                        ? Icons.arrow_downward
                        : (_totalDifference > 0 ? Icons.arrow_upward : null),
                iconColor:
                    _totalDifference < 0
                        ? Colors.red
                        : (_totalDifference > 0 ? Colors.green : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEfficiencyBar(),
      ],
    );
  }

  Widget _buildEfficiencyBar() {
    double progress = _overallEfficiency / 100;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;

    Color barColor;
    if (_overallEfficiency < 70) {
      barColor = Colors.red;
    } else if (_overallEfficiency >= 70 && _overallEfficiency < 85) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Efficiency Bar:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text(
              '${_overallEfficiency.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
