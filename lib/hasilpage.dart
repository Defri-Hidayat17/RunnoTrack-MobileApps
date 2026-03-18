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

  String _selectedDate = DateFormat('dd/MM/yy').format(DateTime.now());
  String? _selectedGroup;
  String? _selectedChecker;
  String? _loggedInAccountType;

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
    // This is called when the dependencies of this State object change.
    // This is a good place to re-read SharedPreferences if they might have been updated
    // by another part of the app (like HomePage).
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

    final String newSelectedDate =
        prefs.getString(_prefsKeySelectedDate) ??
        DateFormat('dd/MM/yy').format(DateTime.now());
    final String? newSelectedGroup = prefs.getString(_prefsKeySelectedGroup);
    final String? newSelectedChecker = prefs.getString(_prefsKeySelectedUser);
    final String? newLoggedInAccountType = prefs.getString('accountType');
    final int newTotalTarget =
        int.tryParse(prefs.getString(_prefsKeyTotalTarget) ?? '0') ?? 0;

    // Selalu perbarui variabel state dengan nilai terbaru dari SharedPreferences.
    // Ini memastikan _fetchTrackingResults menggunakan data yang paling mutakhir.
    // Ini juga mengatasi masalah "kelap kelip" total target.
    if (mounted) {
      setState(() {
        _selectedDate = newSelectedDate;
        _selectedGroup = newSelectedGroup;
        _selectedChecker = newSelectedChecker;
        _loggedInAccountType = newLoggedInAccountType;
        _totalTarget =
            newTotalTarget; // _totalTarget selalu dari SharedPreferences
      });
    }

    // Sekarang, dengan variabel state yang sudah diperbarui, ambil hasil tracking
    if (_selectedGroup != null && _selectedChecker != null) {
      await _fetchTrackingResults(
        date: _selectedDate,
        group: _selectedGroup!,
        checker: _selectedChecker!,
        target:
            _totalTarget, // Menggunakan _totalTarget dari state yang sudah diperbarui
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
    required int
    target, // Ini adalah nilai target terbaru dari SharedPreferences
  }) async {
    // print(
    //   'DEBUG Hasilpage: _fetchTrackingResults called with date=$date, group=$group, checker=$checker, target=$target',
    // );
    if (group == null || checker == null) {
      // print(
      //   'DEBUG Hasilpage: Skipping API call due to null parameters: Group=$group, Checker=$checker',
      // );
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
    final url =
        '$_baseUrl/get_tracking_results.php?entry_date=$formattedDate&group_code=$group&checker_username=$checker';
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
          bool entryConfirmedStatus = false;
          // int fetchedTotalTarget = target; // Baris ini tidak lagi kita butuhkan

          if (responseData['data'] != null &&
              responseData['data'] is List &&
              responseData['data'].isNotEmpty) {
            var entryItem = responseData['data'][0];
            entryConfirmedStatus = (entryItem['is_confirmed'] == '1');
            // Hapus atau komentari baris di bawah ini.
            // Kita tidak ingin menimpa _totalTarget dari state dengan nilai dari database yang mungkin lama.
            // fetchedTotalTarget = int.tryParse(entryItem['total_target'].toString()) ?? target;

            if (entryItem['cards'] != null && entryItem['cards'] is List) {
              for (int i = 0; i < entryItem['cards'].length; i++) {
                var cardJson = entryItem['cards'][i];
                int actualQtyInt =
                    int.tryParse(cardJson['qty'].toString()) ?? 0;
                fetchedCards.add(
                  CardData(
                    id: i + 1,
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
          // print(
          //   'DEBUG Hasilpage: Data successfully parsed. Cards count: ${fetchedCards.length}',
          // );

          if (mounted) {
            setState(() {
              _resultCards = fetchedCards;
              // Hapus baris ini. _totalTarget sudah diatur di _refreshData dari SharedPreferences.
              // _totalTarget = fetchedTotalTarget;
              _totalActual = currentTotalActual;
              _totalDifference =
                  currentTotalActual -
                  _totalTarget; // Gunakan _totalTarget dari state Hasilpage
              _overallEfficiency =
                  _totalTarget > 0
                      ? (currentTotalActual / _totalTarget) * 100
                      : 0.0;
              _isEntryConfirmed = entryConfirmedStatus;
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
              _isEntryConfirmed = false;
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
            _isEntryConfirmed = false;
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

  void _updateCardData(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
    String qty,
    bool hasChanges,
  ) {
    if (mounted) {
      final index = _resultCards.indexWhere((card) => card.id == id);
      if (index != -1) {
        final oldCard = _resultCards[index];

        bool needsUpdate = false;
        if (oldCard.model != model) needsUpdate = true;
        if (oldCard.runnoAwal != runnoAwal) needsUpdate = true;
        if (oldCard.runnoAkhir != runnoAkhir) needsUpdate = true;
        if (oldCard.qty != qty) needsUpdate = true;
        if (oldCard.hasChanges != hasChanges) needsUpdate = true;

        if (needsUpdate) {
          setState(() {
            _resultCards[index] = oldCard.copyWith(
              model: model,
              runnoAwal: runnoAwal,
              runnoAkhir: runnoAkhir,
              qty: qty,
              hasChanges: hasChanges,
            );
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
    _totalActual = currentTotalActual;
    _totalDifference = _totalActual - _totalTarget;
    _overallEfficiency =
        _totalTarget > 0 ? (_totalActual / _totalTarget) * 100 : 0.0;
  }

  Future<void> _saveCardData(int id) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa diubah.');
      return;
    }
    if (_selectedGroup == null || _selectedChecker == null) {
      _showSnackBar('Grup atau Checker tidak valid.');
      return;
    }

    final cardToSave = _resultCards.firstWhere((card) => card.id == id);
    if (!cardToSave.hasChanges) {
      _showSnackBar('Tidak ada perubahan pada kartu ini untuk disimpan!');
      return;
    }

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

    List<Map<String, dynamic>> cardsToUpdate =
        _resultCards.map((card) {
          return {
            'model': card.model,
            'runno_awal': card.runnoAwal,
            'runno_akhir': card.runnoAkhir,
            'qty': int.tryParse(card.qty) ?? 0,
          };
        }).toList();

    Map<String, dynamic> postData = {
      'entry_date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yy').parse(_selectedDate)),
      'group_code': _selectedGroup,
      'checker_username': _selectedChecker,
      'total_target': _totalTarget,
      'cards': cardsToUpdate,
    };

    // print('DEBUG Hasilpage: Data to update: ${json.encode(postData)}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_tracking_data.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      // print(
      //   'DEBUG Hasilpage: Update Card Response Status Code: ${response.statusCode}',
      // );
      // print('DEBUG Hasilpage: Update Card Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar('Kartu berhasil diperbarui!');
          // After successful save, refresh the data to reflect changes and reset hasChanges
          if (_selectedGroup != null && _selectedChecker != null) {
            _fetchTrackingResults(
              date: _selectedDate,
              group: _selectedGroup!,
              checker: _selectedChecker!,
              target: _totalTarget,
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

  Future<void> _deleteCardData(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
  ) async {
    if (_isEntryConfirmed) {
      _showSnackBar('Data sudah dikonfirmasi, tidak bisa dihapus.');
      return;
    }
    if (_selectedGroup == null || _selectedChecker == null) {
      _showSnackBar('Grup atau Checker tidak valid.');
      return;
    }

    bool confirm =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi Hapus'),
              content: const Text(
                'Apakah Anda yakin ingin menghapus kartu ini?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    final formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateFormat('dd/MM/yy').parse(_selectedDate));

    Map<String, dynamic> postData = {
      'entry_date': formattedDate,
      'group_code': _selectedGroup,
      'checker_username': _selectedChecker,
      'model': model,
      'runno_awal': runnoAwal,
      'runno_akhir': runnoAkhir,
    };

    // print('DEBUG Hasilpage: Data to delete: ${json.encode(postData)}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_tracking_card.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      // print(
      //   'DEBUG Hasilpage: Delete Card Response Status Code: ${response.statusCode}',
      // );
      // print('DEBUG Hasilpage: Delete Card Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          _showSnackBar('Kartu berhasil dihapus!');
          // After successful delete, refresh the data
          if (mounted && _selectedGroup != null && _selectedChecker != null) {
            _fetchTrackingResults(
              date: _selectedDate,
              group: _selectedGroup!,
              checker: _selectedChecker!,
              target: _totalTarget,
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
    };
    // print(
    //   'DEBUG Hasilpage: _confirmTrackingEntry POST data: ${json.encode(postData)}',
    // );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/confirm_tracking_entry.php'),
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
          if (mounted) {
            setState(() {
              _isEntryConfirmed = true;
            });
          }
          _showSnackBar('Data berhasil dikonfirmasi!');
          // print('DEBUG Hasilpage: _confirmTrackingEntry success.');
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
        "Status Konfirmasi: ${_isEntryConfirmed ? 'Confirmed' : 'Pending'}";

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

    Color confirmationColor = _isEntryConfirmed ? Colors.green : Colors.orange;
    String confirmationText = _isEntryConfirmed ? 'Confirmed' : 'Pending';

    const double bottomNavBarTotalHeight = 90.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Entry Status
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8, // Menyamakan tinggi
                              ),
                              decoration: BoxDecoration(
                                color: confirmationColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  10,
                                ), // Sedikit lebih besar
                              ),
                              child: Text(
                                'Entry Status: $confirmationText',
                                style: TextStyle(
                                  color: confirmationColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Refresh Button
                        Center(
                          // Menggunakan Center untuk tombol ikon
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _refreshData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF4CAF50,
                              ), // Warna hijau
                              padding: const EdgeInsets.all(
                                8.0,
                              ), // Padding disesuaikan untuk ikon
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(
                                48,
                                48,
                              ), // Ukuran minimum agar konsisten
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24, // Ukuran ikon diperbesar
                            ),
                          ),
                        ),

                        // Konfirmasi Data / Kirim WhatsApp Button
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerRight,
                            child:
                                _isEntryConfirmed && _resultCards.isNotEmpty
                                    ? ElevatedButton.icon(
                                      onPressed: () => _sendToWhatsApp(),
                                      icon: const Icon(
                                        Icons.message,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Kirim WhatsApp',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF25D366,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    )
                                    : (!_isEntryConfirmed &&
                                            _resultCards.isNotEmpty
                                        ? ElevatedButton(
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () =>
                                                      _confirmTrackingEntry(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0D2547,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            // Teks diubah menjadi "Konfirmasi" saja
                                            'Konfirmasi',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                        : const SizedBox.shrink()),
                          ),
                        ),
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
                        : Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _resultCards.length,
                            itemBuilder: (context, index) {
                              final card = _resultCards[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ), // Padding antar kartu
                                child: HasilpageCardWidget(
                                  cardData: card,
                                  darkBlueCardBorderSide:
                                      darkBlueCardBorderSide,
                                  cardBackgroundColor: Colors.white,
                                  readOnly:
                                      _isEntryConfirmed, // Tetap readOnly jika sudah dikonfirmasi
                                  onDataChanged: _updateCardData,
                                  onSave: _saveCardData,
                                  onDelete: _deleteCardData,
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
      ),
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
                value: _totalDifference.toString(),
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

    Color barColor = Colors.grey;
    if (_overallEfficiency >= 100) {
      barColor = Colors.green;
    } else if (_overallEfficiency > 0) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
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
