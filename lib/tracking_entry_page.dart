// lib/tracking_entry_page.dart (FINAL REVISED VERSION - CORRECTED)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async'; // Import untuk Timer
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

import 'package:runnotrack/models/card_data.dart';
import 'package:runnotrack/models/history_entry.dart';
import 'package:runnotrack/hasilpage_card_widget.dart';

// DEFINE ULANG GAYA GLOBAL DEFAULT DI SINI AGAR BISA DIAKSES
// Idealnya, ini diletakkan di file terpisah (misal: constants.dart) dan diimpor.
const SystemUiOverlayStyle _globalDefaultSystemUiOverlayStyle =
    SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

const String _baseUrl = 'http://192.168.1.10/runnotrack_api';

class TrackingEntryPage extends StatefulWidget {
  final HistoryEntry? initialEntry;

  const TrackingEntryPage({super.key, this.initialEntry});

  @override
  State<TrackingEntryPage> createState() => _TrackingEntryPageState();
}

class _TrackingEntryPageState extends State<TrackingEntryPage> {
  static const Color _darkBlueStrokeColor = Color(0xFF03112B);
  static const List<BoxShadow> _commonBoxShadow = [
    BoxShadow(
      color: Colors.grey,
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const double _kActionElementHeight = 44.0;
  static const double _kButtonHorizontalPadding = 15.0;
  static const double _kSpacing = 8.0;

  static const String _prefsKeySelectedDate = 'selectedTrackingDate';
  static const String _prefsKeySelectedGroup = 'selected_group';
  static const String _prefsKeySelectedUser = 'selected_user';
  static const String _prefsKeyTotalTarget = 'total_target';

  static const String _prefsKeyLastConfirmedStatus = 'lastConfirmedStatus';
  static const String _prefsKeyLastConfirmedDate = 'lastConfirmedDate';
  static const String _prefsKeyLastConfirmedGroup = 'lastConfirmedGroup';
  static const String _prefsKeyLastConfirmedChecker = 'lastConfirmedChecker';

  String _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
  TextEditingController _groupController = TextEditingController();
  TextEditingController _checkerController = TextEditingController();
  TextEditingController _targetController = TextEditingController();

  String? _loggedInUserId;

  List<CardData> _resultCards = [];
  bool _isLoading = false;

  int _totalActual = 0;
  int _totalDifference = 0;
  double _overallEfficiency = 0.0;
  bool _isEntryConfirmed = false;
  int? _trackingEntryId;

  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    // Terapkan gaya UI sistem khusus untuk TrackingEntryPage
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: _darkBlueStrokeColor, // Status bar khusus: Biru Gelap
        statusBarIconBrightness: Brightness.light, // Ikon terang
        statusBarBrightness: Brightness.dark, // Untuk iOS
        systemNavigationBarColor: Colors.white, // Navigation bar tetap putih
        systemNavigationBarIconBrightness: Brightness.dark, // Ikon gelap
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });

    _targetController.addListener(_onTargetChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _groupController.dispose();
    _checkerController.dispose();
    _targetController.removeListener(_onTargetChanged);
    _targetController.dispose();

    // --- PENTING: KEMBALIKAN KE GAYA GLOBAL DEFAULT SAAT KELUAR HALAMAN ---
    SystemChrome.setSystemUIOverlayStyle(_globalDefaultSystemUiOverlayStyle);

    super.dispose();
  }

  void _onTargetChanged() {
    _recalculateSummaryValues();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.initialEntry != null) {
      if (mounted) {
        setState(() {
          _selectedDate = widget.initialEntry!.entryDate;
          _groupController.text = widget.initialEntry!.groupCode;
          _checkerController.text = widget.initialEntry!.checkerUsername;
          _targetController.text = widget.initialEntry!.totalTarget.toString();
          _loggedInUserId = prefs.getString('user_id');
          _isEntryConfirmed = widget.initialEntry!.isConfirmed;
          _trackingEntryId = widget.initialEntry!.id;
          _totalActual = widget.initialEntry!.totalActualQty;
          _totalDifference = widget.initialEntry!.difference;
          _overallEfficiency = widget.initialEntry!.efficiencyPercentage;
        });
      }
      if (_groupController.text.isNotEmpty &&
          _checkerController.text.isNotEmpty &&
          _loggedInUserId != null) {
        await _fetchTrackingResults(
          date: _selectedDate,
          group: _groupController.text,
          checker: _checkerController.text,
          target: int.tryParse(_targetController.text) ?? 0,
          userId: _loggedInUserId!,
          trackingEntryId: _trackingEntryId,
        );
      }
    } else {
      _refreshDataForNewEntry();
    }
  }

  Future<void> _refreshDataForNewEntry() async {
    final prefs = await SharedPreferences.getInstance();

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
      if (mounted) {
        setState(() {
          _selectedDate = lastConfirmedDate;
          _groupController.text = lastConfirmedGroup;
          _checkerController.text = lastConfirmedChecker;
          _loggedInUserId = prefs.getString('user_id');
          _targetController.text = '0';
          _resultCards = [];
          _totalActual = 0;
          _totalDifference = 0;
          _overallEfficiency = 0.0;
          _isEntryConfirmed = true;
          _trackingEntryId = null;
        });
      }
      await prefs.remove(_prefsKeyLastConfirmedStatus);
      await prefs.remove(_prefsKeyLastConfirmedDate);
      await prefs.remove(_prefsKeyLastConfirmedGroup);
      await prefs.remove(_prefsKeyLastConfirmedChecker);
      return;
    }

    final String newSelectedDate =
        prefs.getString(_prefsKeySelectedDate) ??
        DateFormat('dd/MM/yy').format(DateTime.now());
    final String? newSelectedGroup = prefs.getString(_prefsKeySelectedGroup);
    final String? newSelectedChecker = prefs.getString(_prefsKeySelectedUser);
    final String? newLoggedInUserId = prefs.getString('user_id');
    final int newTotalTarget =
        int.tryParse(prefs.getString(_prefsKeyTotalTarget) ?? '0') ?? 0;

    if (mounted) {
      setState(() {
        _selectedDate = newSelectedDate;
        _groupController.text = newSelectedGroup ?? '';
        _checkerController.text = newSelectedChecker ?? '';
        _loggedInUserId = newLoggedInUserId;
        _targetController.text = newTotalTarget.toString();
        _trackingEntryId = null;
        _isEntryConfirmed = false;
      });
    }

    if (_groupController.text.isNotEmpty &&
        _checkerController.text.isNotEmpty &&
        _loggedInUserId != null) {
      await _fetchTrackingResults(
        date: _selectedDate,
        group: _groupController.text,
        checker: _checkerController.text,
        target: int.tryParse(_targetController.text) ?? 0,
        userId: _loggedInUserId!,
        trackingEntryId: null,
      );
    } else {
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference =
              _totalActual - (int.tryParse(_targetController.text) ?? 0);
          _overallEfficiency =
              (int.tryParse(_targetController.text) ?? 0) > 0
                  ? (_totalActual /
                          (int.tryParse(_targetController.text) ?? 0)) *
                      100
                  : 0.0;
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
    required String userId,
    int? trackingEntryId,
  }) async {
    if (group.isEmpty || checker.isEmpty || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference = _totalActual - target;
          _overallEfficiency = target > 0 ? (_totalActual / target) * 100 : 0.0;
          _isEntryConfirmed = false;
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
    String url;

    if (trackingEntryId != null) {
      url =
          '$_baseUrl/get_tracking_card_details.php?tracking_entry_id=$trackingEntryId';
    } else {
      url =
          '$_baseUrl/get_tracking_results.php?entry_date=$formattedDate&group_code=$group&checker_username=$checker&user_id=$userId';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          List<CardData> fetchedCards = [];
          int currentTotalActual = 0;
          bool entryConfirmedStatus = false;
          int fetchedTotalTarget = target;

          if (trackingEntryId != null) {
            entryConfirmedStatus = responseData['is_confirmed'] == 1;
            if (responseData['data'] != null && responseData['data'] is List) {
              for (int i = 0; i < responseData['data'].length; i++) {
                var cardJson = responseData['data'][i];
                int actualQtyInt =
                    int.tryParse(cardJson['qty'].toString()) ?? 0;
                fetchedCards.add(
                  CardData(
                    id:
                        DateTime.now().microsecondsSinceEpoch +
                        Random().nextInt(1000), // Local ID
                    cardDetailId: int.tryParse(
                      cardJson['id'].toString(),
                    ), // DB ID
                    model: cardJson['model'] ?? '',
                    runnoAwal: cardJson['runno_awal'] ?? '',
                    runnoAkhir: cardJson['runno_akhir'] ?? '',
                    qty: actualQtyInt.toString(),
                    hasChanges: false,
                  ),
                );
                currentTotalActual += actualQtyInt;
              }
            }
          } else {
            if (responseData['data'] != null &&
                responseData['data'] is List &&
                responseData['data'].isNotEmpty) {
              var entryItem = responseData['data'][0];
              entryConfirmedStatus =
                  int.tryParse(entryItem['is_confirmed'].toString()) == 1;
              fetchedTotalTarget =
                  int.tryParse(entryItem['total_target'].toString()) ?? 0;
              _trackingEntryId = int.tryParse(
                entryItem['id'].toString(),
              ); // Ensure _trackingEntryId is set

              // Update state for date, group, checker from fetched data
              if (mounted) {
                setState(() {
                  _selectedDate = DateFormat('dd/MM/yy').format(
                    DateFormat('yyyy-MM-dd').parse(entryItem['entry_date']),
                  );
                  _groupController.text = entryItem['group_code'] ?? '';
                  _checkerController.text = entryItem['checker_username'] ?? '';
                  _targetController.text = fetchedTotalTarget.toString();
                });
              }

              if (entryItem['cards'] != null && entryItem['cards'] is List) {
                for (int i = 0; i < entryItem['cards'].length; i++) {
                  var cardJson = entryItem['cards'][i];
                  int actualQtyInt =
                      int.tryParse(cardJson['qty'].toString()) ?? 0;
                  fetchedCards.add(
                    CardData(
                      id:
                          DateTime.now().microsecondsSinceEpoch +
                          Random().nextInt(1000), // Local ID
                      cardDetailId: int.tryParse(
                        cardJson['id'].toString(),
                      ), // DB ID
                      model: cardJson['model'] ?? '',
                      runnoAwal: cardJson['runno_awal'] ?? '',
                      runnoAkhir: cardJson['runno_akhir'] ?? '',
                      qty: actualQtyInt.toString(),
                      hasChanges: false,
                    ),
                  );
                  currentTotalActual += actualQtyInt;
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              _resultCards = fetchedCards;
              _totalActual = currentTotalActual;
              _isEntryConfirmed = entryConfirmedStatus;
              _recalculateSummaryValues();
            });
          }
        } else {
          _showSnackBar('Tidak ada data hasil untuk kriteria yang dipilih.');
          if (mounted) {
            setState(() {
              _resultCards = [];
              _totalActual = 0;
              _totalDifference =
                  _totalActual - (int.tryParse(_targetController.text) ?? 0);
              _overallEfficiency =
                  (int.tryParse(_targetController.text) ?? 0) > 0
                      ? (_totalActual /
                              (int.tryParse(_targetController.text) ?? 0)) *
                          100
                      : 0.0;
              _isEntryConfirmed = false;
            });
          }
        }
      } else {
        _showSnackBar(
          'Failed to load results. Status code: ${response.statusCode}.',
        );
        if (mounted) {
          setState(() {
            _resultCards = [];
            _totalActual = 0;
            _totalDifference =
                _totalActual - (int.tryParse(_targetController.text) ?? 0);
            _overallEfficiency =
                (int.tryParse(_targetController.text) ?? 0) > 0
                    ? (_totalActual /
                            (int.tryParse(_targetController.text) ?? 0)) *
                        100
                    : 0.0;
            _isEntryConfirmed = false;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error fetching results: $e');
      if (mounted) {
        setState(() {
          _resultCards = [];
          _totalActual = 0;
          _totalDifference =
              _totalActual - (int.tryParse(_targetController.text) ?? 0);
          _overallEfficiency =
              (int.tryParse(_targetController.text) ?? 0) > 0
                  ? (_totalActual /
                          (int.tryParse(_targetController.text) ?? 0)) *
                      100
                  : 0.0;
          _isEntryConfirmed = false;
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

  void _onCardDataChanged(int localId, CardData updatedCardData) {
    if (mounted) {
      final index = _resultCards.indexWhere((card) => card.id == localId);
      if (index != -1) {
        if (_resultCards[index] != updatedCardData) {
          setState(() {
            _resultCards[index] = updatedCardData.copyWith(hasChanges: true);
            _recalculateSummaryValues();
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
    int currentTarget = int.tryParse(_targetController.text) ?? 0;

    if (mounted) {
      setState(() {
        _totalActual = currentTotalActual;
        _totalDifference = currentTotalActual - currentTarget;
        _overallEfficiency =
            currentTarget > 0
                ? (currentTotalActual / currentTarget) * 100
                : 0.0;
      });
    }
  }

  // Fungsi terpusat untuk menyimpan semua data (header dan kartu)
  // Mengembalikan boolean untuk menunjukkan keberhasilan API.
  Future<bool> _saveTrackingEntry({bool refetchAfterSave = false}) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa diubah.');
      return false;
    }
    if (_groupController.text.isEmpty ||
        _checkerController.text.isEmpty ||
        _loggedInUserId == null) {
      _showSnackBar('Grup, Checker, atau User ID tidak valid.');
      return false;
    }

    // Validasi kartu sebelum menyimpan
    for (var card in _resultCards) {
      if (card.model.isEmpty ||
          card.runnoAwal.isEmpty ||
          card.runnoAkhir.isEmpty ||
          card.qty.isEmpty) {
        _showSnackBar('Harap isi semua kolom pada kartu.');
        return false;
      }
      final int? parsedQty = int.tryParse(card.qty);
      if (parsedQty == null || parsedQty < 0) {
        _showSnackBar('QTY harus berupa angka yang valid dan non-negatif!');
        return false;
      }
    }

    List<Map<String, dynamic>> cardsToSend =
        _resultCards.map((card) => card.toJson()).toList();

    Map<String, dynamic> postData = {
      'entry_date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yy').parse(_selectedDate)),
      'group_code': _groupController.text,
      'checker_username': _checkerController.text,
      'total_target': int.tryParse(_targetController.text) ?? 0,
      'user_id': _loggedInUserId,
      'tracking_entry_id': _trackingEntryId,
      'cards': cardsToSend,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          // _showSnackBar('Data berhasil disimpan!'); // DIHAPUS
          if (responseData['tracking_entry_id'] != null && mounted) {
            setState(() {
              _trackingEntryId = responseData['tracking_entry_id'];
            });
          }
          if (refetchAfterSave) {
            await _fetchTrackingResults(
              date: _selectedDate,
              group: _groupController.text,
              checker: _checkerController.text,
              target: int.tryParse(_targetController.text) ?? 0,
              userId: _loggedInUserId!,
              trackingEntryId: _trackingEntryId,
            );
          }
          return true; // Berhasil
        } else {
          _showSnackBar('Gagal menyimpan data: ${responseData['message']}');
          return false; // Gagal
        }
      } else {
        _showSnackBar(
          'Gagal menyimpan data. Kode status: ${response.statusCode}. Respons: ${response.body}',
        );
        return false; // Gagal
      }
    } catch (e) {
      _showSnackBar('Error saat menyimpan data: $e');
      return false; // Gagal
    }
  }

  Future<void> _onSaveUpdatedCard(CardData cardToSave) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa diubah.');
      return;
    }

    final index = _resultCards.indexWhere((card) => card.id == cardToSave.id);
    if (index != -1) {
      setState(() {
        _resultCards[index] = cardToSave.copyWith(hasChanges: false);
      });
    }
  }

  // Mengubah tipe parameter menjadi 'int' (non-nullable)
  Future<void> _onDeleteCard(int cardDetailId) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa dihapus.');
      return;
    }
    if (_groupController.text.isEmpty ||
        _checkerController.text.isEmpty ||
        _loggedInUserId == null) {
      _showSnackBar('Grup, Checker, atau User ID tidak valid.');
      return;
    }
    // Tidak perlu lagi cek null di sini karena parameter sudah 'int'

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
          if (mounted &&
              _groupController.text.isNotEmpty &&
              _checkerController.text.isNotEmpty &&
              _loggedInUserId != null) {
            // Setelah menghapus, ambil ulang data untuk memperbarui daftar kartu dan ringkasan
            await _fetchTrackingResults(
              date: _selectedDate,
              group: _groupController.text,
              checker: _checkerController.text,
              target: int.tryParse(_targetController.text) ?? 0,
              userId: _loggedInUserId!,
              trackingEntryId: _trackingEntryId,
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

  // Helper function untuk menyimpan semua data dan menangani ID kartu baru sebelum konfirmasi
  Future<bool> _saveAllChangesBeforeConfirm() async {
    // Kita perlu refetch jika ini adalah entri baru (_trackingEntryId saat ini null)
    // atau jika ada kartu baru (cardDetailId null untuk kartu apa pun).
    final bool needsRefetch =
        _trackingEntryId == null ||
        _resultCards.any((card) => card.cardDetailId == null);

    final bool saveSuccessful = await _saveTrackingEntry(
      refetchAfterSave: needsRefetch,
    );

    return saveSuccessful;
  }

  Future<void> _confirmTrackingEntry() async {
    if (_trackingEntryId == null && _resultCards.isEmpty) {
      _showSnackBar(
        'Tidak dapat mengkonfirmasi: Tidak ada data untuk disimpan.',
      );
      return;
    }

    // Pertama, simpan semua perubahan yang tertunda (header + kartu).
    // Ini juga akan refetch jika kartu baru atau entri baru dibuat,
    // memastikan cardDetailId terisi.
    bool changesSaved = await _saveAllChangesBeforeConfirm();
    if (!changesSaved) {
      _showSnackBar(
        'Gagal menyimpan perubahan sebelum konfirmasi. Tidak dapat melanjutkan.',
      );
      return;
    }

    // Setelah menyimpan, _trackingEntryId harus sudah terisi.
    if (_trackingEntryId == null) {
      _showSnackBar(
        'Gagal mendapatkan ID entri tracking setelah penyimpanan awal. Tidak dapat melanjutkan konfirmasi.',
      );
      return;
    }

    Map<String, dynamic> postData = {'tracking_entry_id': _trackingEntryId};

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/confirm_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar(
            'Data berhasil dikonfirmasi dan disimpan!',
          ); // Notifikasi di sini
          if (mounted) {
            setState(() {
              _isEntryConfirmed = true;
            });
          }

          // Tidak perlu _fetchTrackingResults di sini, karena _saveAllChangesBeforeConfirm sudah melakukannya jika diperlukan,
          // dan konfirmasi hanya mengubah flag `is_confirmed`.
          // Status UI `_isEntryConfirmed` sudah diperbarui.
          // Hitung ulang ringkasan untuk memastikan.
          _recalculateSummaryValues();

          if (widget.initialEntry != null) {
            final updatedHistoryEntry = widget.initialEntry!.copyWith(
              isConfirmed: true,
              totalActualQty: _totalActual,
              difference: _totalDifference,
              efficiencyPercentage: _overallEfficiency,
              totalTarget: int.tryParse(_targetController.text) ?? 0,
              entryDate: _selectedDate,
              groupCode: _groupController.text,
              checkerUsername: _checkerController.text,
            );
            Navigator.of(context).pop(updatedHistoryEntry);
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_prefsKeyLastConfirmedStatus, true);
            await prefs.setString(_prefsKeyLastConfirmedDate, _selectedDate);
            await prefs.setString(
              _prefsKeyLastConfirmedGroup,
              _groupController.text,
            );
            await prefs.setString(
              _prefsKeyLastConfirmedChecker,
              _checkerController.text,
            );
            await prefs.remove(_prefsKeySelectedDate);
            await prefs.remove(_prefsKeySelectedGroup);
            await prefs.remove(_prefsKeySelectedUser);
            await prefs.remove(_prefsKeyTotalTarget);

            Navigator.of(context).pop(null);
          }
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

  Future<void> _unconfirmTrackingEntry() async {
    if (_trackingEntryId == null) {
      _showSnackBar(
        'Tidak dapat membatalkan konfirmasi: ID entri tracking tidak ditemukan.',
      );
      return;
    }

    Map<String, dynamic> postData = {'tracking_entry_id': _trackingEntryId};

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/unconfirm_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar(
            'Data berhasil dibatalkan konfirmasi! Anda sekarang dapat mengedit data.',
          );
          if (mounted) {
            setState(() {
              _isEntryConfirmed = false;
            });
          }

          // Tetap di halaman ini dan refresh data untuk memungkinkan pengeditan
          await _fetchTrackingResults(
            date: _selectedDate,
            group: _groupController.text,
            checker: _checkerController.text,
            target: int.tryParse(_targetController.text) ?? 0,
            userId: _loggedInUserId!,
            trackingEntryId: _trackingEntryId,
          );
          // TIDAK POP, TETAP DI HALAMAN INI
        } else {
          _showSnackBar(
            'Gagal membatalkan konfirmasi data: ${responseData['message']}',
          );
        }
      } else {
        _showSnackBar(
          'Gagal membatalkan konfirmasi data. Kode status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error saat membatalkan konfirmasi data: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isEntryConfirmed) {
      _showSnackBar(
        'Tidak bisa mengubah tanggal saat data sudah dikonfirmasi.',
      );
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd/MM/yy').parse(_selectedDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null &&
        picked != DateFormat('dd/MM/yy').parse(_selectedDate)) {
      setState(() {
        _selectedDate = DateFormat('dd/MM/yy').format(picked);
      });
    }
  }

  void _addNewCard() {
    if (_isEntryConfirmed) {
      _showSnackBar('Tidak bisa menambah kartu saat data sudah dikonfirmasi.');
      return;
    }

    final newCard = CardData(
      id:
          DateTime.now().microsecondsSinceEpoch +
          Random().nextInt(1000), // Local ID
      cardDetailId: null, // Null for new cards, will be assigned by backend
      model: '',
      runnoAwal: '',
      runnoAkhir: '',
      qty: '0',
      hasChanges: true, // Mark as having changes for explicit saving later
    );

    setState(() {
      _resultCards.add(newCard);
    });
    // Secara otomatis gulir ke kartu baru
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.animateToPage(
        _resultCards.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
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

    const double bottomNavBarTotalHeight = kBottomNavigationBarHeight + 16.0;

    // --- HAPUS AnnotatedRegion DI SINI ---
    return Scaffold(
      backgroundColor: Colors.white, // Background halaman putih
      body: Column(
        children: [
          // Custom Header - HANYA back button dan logo
          Container(
            color: _darkBlueStrokeColor,
            padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).padding.top +
                  12.0, // Tinggi status bar + padding vertikal
              bottom: 12.0,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                // Hanya baris ini di dalam header biru gelap
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (widget.initialEntry != null) {
                        final currentEntry = widget.initialEntry!.copyWith(
                          isConfirmed: _isEntryConfirmed,
                          totalActualQty: _totalActual,
                          difference: _totalDifference,
                          efficiencyPercentage: _overallEfficiency,
                          totalTarget:
                              int.tryParse(_targetController.text) ?? 0,
                          entryDate: _selectedDate,
                          groupCode: _groupController.text,
                          checkerUsername: _checkerController.text,
                        );
                        Navigator.of(context).pop(currentEntry);
                      } else {
                        Navigator.of(context).pop(null);
                      }
                    },
                  ),
                  SvgPicture.asset('assets/images/logolengkap.svg', height: 30),
                ],
              ),
            ),
          ),

          // Bagian baru untuk Tanggal, Grup, Checker (di bawah header biru)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ), // Sesuaikan padding
            child: Row(
              children: [
                Expanded(
                  child: _buildEditableField(
                    label: 'Tanggal',
                    value: _selectedDate,
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context),
                    readOnly: _isEntryConfirmed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEditableTextField(
                    label: 'Grup',
                    controller: _groupController,
                    icon: Icons.group,
                    readOnly: _isEntryConfirmed,
                    onChanged: (value) {
                      // if (!_isEntryConfirmed) { // DIHAPUS
                      //   _debounceSave(); // DIHAPUS
                      // }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEditableTextField(
                    label: 'Checker',
                    controller: _checkerController,
                    icon: Icons.person,
                    readOnly: _isEntryConfirmed,
                    onChanged: (value) {
                      // if (!_isEntryConfirmed) { // DIHAPUS
                      //   _debounceSave(); // DIHAPUS
                      // }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Summary Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummarySection(),
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
                padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status
                        Expanded(
                          flex: 2,
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

                        // Refresh Button
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : (widget.initialEntry != null
                                      ? () => _initializeData()
                                      : () => _refreshDataForNewEntry()),
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

                        // Confirm / Unconfirm Button
                        Expanded(
                          flex: 3,
                          child:
                              _isEntryConfirmed
                                  ? ElevatedButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => _unconfirmTrackingEntry(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        213,
                                        14,
                                        0,
                                      ),
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
                                      'Batalkan Konfirmasi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                  : ElevatedButton(
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
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : _resultCards.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text(
                                    'Tidak ada data hasil untuk kriteria yang dipilih.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                controller: _pageController,
                                itemCount: _resultCards.length,
                                padding: EdgeInsets.only(
                                  bottom: bottomNavBarTotalHeight,
                                ),
                                itemBuilder: (context, index) {
                                  final card = _resultCards[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 8.0,
                                    ),
                                    child: HasilpageCardWidget(
                                      key: ValueKey(card.id),
                                      cardData: card,
                                      darkBlueCardBorderSide:
                                          darkBlueCardBorderSide,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _isEntryConfirmed
              ? null // Tidak tampilkan FAB jika sudah dikonfirmasi
              : FloatingActionButton(
                // Tampilkan FAB jika belum dikonfirmasi
                onPressed: _addNewCard,
                backgroundColor: _darkBlueStrokeColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: Container(
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
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: readOnly ? Colors.grey[700] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
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
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  onChanged: readOnly ? null : onChanged,
                  readOnly: readOnly,
                  style: TextStyle(
                    fontSize: 16,
                    color: readOnly ? Colors.grey[700] : Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEditableTextField(
                label: 'Target',
                controller: _targetController,
                icon: Icons.adjust,
                keyboardType: TextInputType.number,
                readOnly: _isEntryConfirmed,
                onChanged: (value) {
                  if (!_isEntryConfirmed) {
                    _recalculateSummaryValues();
                    // _debounceSave(); // DIHAPUS
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                    const Text(
                      'Total QTY',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _totalActual.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                    const Text(
                      'Difference',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _totalDifference > 0
                                ? '+${_totalDifference.toString()}'
                                : _totalDifference.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  _totalDifference < 0
                                      ? Colors.red
                                      : (_totalDifference > 0
                                          ? Colors.green
                                          : Colors.blue),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_totalDifference != 0)
                          Icon(
                            _totalDifference < 0
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color:
                                _totalDifference < 0
                                    ? Colors.red
                                    : Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
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
