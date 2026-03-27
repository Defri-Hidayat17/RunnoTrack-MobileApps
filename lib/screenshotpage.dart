// lib/screenshotpage.dart (FINAL REVISI - FIX BACKGROUND HITAM & FLOW CRASH)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:runnotrack/models/history_entry.dart';
import 'package:runnotrack/models/card_data.dart';
import 'package:runnotrack/riwayat_card_widget.dart';

// DEFINE ULANG GAYA GLOBAL DEFAULT DI SINI AGAR BISA DIAKSES
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
const String _baseImageUrl = 'http://192.168.1.10/runnotrack_api/images/';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ScreenshotPage extends StatefulWidget {
  final HistoryEntry entry;
  final String userName;
  final String userPhotoUrl;

  const ScreenshotPage({
    super.key,
    required this.entry,
    required this.userName,
    required this.userPhotoUrl,
  });

  @override
  State<ScreenshotPage> createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage> {
  late String _userName;
  late String _userPhotoUrl;
  List<CardData> _detailedCards = [];
  bool _isLoadingDetails = true;
  String _errorMessage = '';

  static const Color _appBarColor = Color(0xFF0D2547);
  static const Color _pageBackgroundColor = Color(0xFFDBE6F2);

  static const Color _tableHeaderBgColor = Color(0xFF2A4E77);
  static const Color _tableRowEvenColor = Color(0xFFF0F5F8);
  static const Color _tableRowOddColor = Color(0xFFE0E8ED);
  static const Color _tableDividerColor = Color(0xFFB0C4DE);

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isTakingScreenshot = false;

  bool _hasScreenshot = false;
  Uint8List? _lastScreenshotBytes;

  @override
  void initState() {
    super.initState();
    _setImmersiveSystemUIOverlay();
    _userName = widget.userName;
    _userPhotoUrl = widget.userPhotoUrl;
    _fetchDetailedCards();

    // Inisialisasi notifikasi lokal
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // ✅ TAMBAHAN: Meminta izin notifikasi saat runtime untuk Android 13+
    _requestNotificationPermission();
  }

  @override
  void dispose() {
    _restoreGlobalDefaultSystemUiOverlay();
    super.dispose();
  }

  void _setImmersiveSystemUIOverlay() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _restoreGlobalDefaultSystemUiOverlay() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_globalDefaultSystemUiOverlayStyle);
  }

  // ✅ TAMBAHAN: Fungsi untuk meminta izin notifikasi
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi ditolak. Notifikasi tidak akan muncul.',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchDetailedCards() async {
    if (widget.entry.id == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ID entri riwayat tidak ditemukan.';
          _isLoadingDetails = false;
        });
      }
      return;
    }

    final url =
        '$_baseUrl/get_tracking_card_details.php?tracking_entry_id=${widget.entry.id}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] &&
            responseData['data'] != null &&
            responseData['data'] is List) {
          List<CardData> fetchedCards = [];
          for (var cardJson in responseData['data']) {
            fetchedCards.add(
              CardData(
                id:
                    DateTime.now().microsecondsSinceEpoch +
                    UniqueKey().hashCode,
                cardDetailId: int.tryParse(cardJson['id'].toString()),
                model: cardJson['model'] ?? '',
                runnoAwal: cardJson['runno_awal'] ?? '',
                runnoAkhir: cardJson['runno_akhir'] ?? '',
                qty: cardJson['qty'].toString(),
                hasChanges: false,
              ),
            );
          }
          if (mounted) {
            setState(() {
              _detailedCards = fetchedCards;
              _isLoadingDetails = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  responseData['message'] ?? 'Gagal memuat detail kartu.';
              _isLoadingDetails = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gagal memuat detail kartu. Status: ${response.statusCode}';
            _isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching card details: $e';
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var statusPhotos = await Permission.photos.request();
      if (statusPhotos.isGranted) {
        return true;
      }

      var statusStorage = await Permission.storage.request();
      if (statusStorage.isGranted) {
        return true;
      }
      return false;
    } else if (Platform.isIOS) {
      var status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  // ✅ MODIFIKASI: _takeScreenshotAndSave() sekarang juga menyimpan ke memory
  Future<void> _takeScreenshotAndSave() async {
    if (mounted) {
      setState(() {
        _isTakingScreenshot = true;
      });
    }

    try {
      bool granted = await _requestPermission();

      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin akses galeri ditolak.')),
          );
        }
        return;
      }

      final image = await _screenshotController.capture();

      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil screenshot.')),
          );
        }
        return;
      }

      _lastScreenshotBytes = image;
      _hasScreenshot =
          true; // ✅ SET _hasScreenshot menjadi true setelah berhasil

      await Gal.putImageBytes(image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Screenshot berhasil disimpan ke galeri! Sekarang bisa dikirim ke WhatsApp.',
            ), // ✅ PESAN LEBIH JELAS
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingScreenshot = false;
        });
      }
    }
  }

  // ✅ NEW: Fungsi untuk membuka WhatsApp dengan nomor dan pesan spesifik
  Future<void> _openWhatsAppWithNumberAndMessage(
    String phoneNumber,
    String message,
  ) async {
    // Format nomor telepon untuk WhatsApp (menghilangkan karakter non-digit dan menambahkan kode negara jika perlu)
    String formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // Contoh: jika nomor tidak diawali '62' dan panjangnya lebih dari 5 digit, tambahkan '62'
    if (!formattedPhoneNumber.startsWith('62') &&
        formattedPhoneNumber.length > 5) {
      formattedPhoneNumber = '62$formattedPhoneNumber';
    }

    // 🔥 PERUBAHAN DI SINI: Jika 'message' kosong, jangan sertakan parameter 'text'
    Uri url;
    if (message.isEmpty) {
      url = Uri.parse("whatsapp://send?phone=$formattedPhoneNumber");
    } else {
      url = Uri.parse(
        "whatsapp://send?phone=$formattedPhoneNumber&text=${Uri.encodeComponent(message)}",
      );
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplikasi WhatsApp tidak ditemukan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka WhatsApp: $e')));
      }
    }
  }

  // 🔥 PERUBAHAN DI SINI: Fungsi ini sekarang hanya mengembalikan string kosong
  String _buildWhatsAppMessage() {
    return ''; // Mengembalikan string kosong agar tidak ada teks otomatis
  }

  Future<void> _showNotif() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'wa_channel',
          'WA Reminder',
          channelDescription: 'Notifikasi pengingat untuk WhatsApp',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'RunnoTrack',
      'Screenshot siap dikirim ke WhatsApp!', // ✅ PERBAIKAN: Pesan notifikasi
      platformChannelSpecifics,
      payload: 'whatsapp_flow',
    );
  }

  // ✅ PERBAIKAN: Fungsi inti untuk alur WA Pro sesuai saranmu
  Future<void> _handleWAFlow() async {
    try {
      // ❗ WAJIB SUDAH SCREENSHOT
      if (!_hasScreenshot) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Silakan ambil screenshot dulu sebelum kirim ke WhatsApp.',
              ),
            ),
          );
        }
        return;
      }

      final String? checkerPhoneNumber = widget.entry.checkerPhoneNumber;

      if (checkerPhoneNumber == null || checkerPhoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nomor WhatsApp checker tidak ditemukan untuk entri ini.',
              ),
            ),
          );
        }
        return;
      }

      // 📝 Bangun pesan WhatsApp (sekarang akan kosong)
      final String whatsappMessage = _buildWhatsAppMessage();

      // 📱 Buka WhatsApp dengan nomor dan pesan yang sudah ditentukan
      await _openWhatsAppWithNumberAndMessage(
        checkerPhoneNumber,
        whatsappMessage,
      );

      // 🔔 notif real (tidak blocking UI)
      // Menggunakan Future.microtask agar notifikasi dijadwalkan secepatnya
      // tanpa blocking UI dan tidak terpengaruh oleh lifecycle app lain.
      Future.microtask(() {
        _showNotif();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dalam alur WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color:
              _pageBackgroundColor, // 🔥 PASTIKAN BACKGROUND TERLIHAT SAAT SCREENSHOT
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    color: _appBarColor,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10.0,
                      bottom: 10.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            'assets/images/logolengkap.svg',
                            height: 40,
                          ),
                          Row(
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    _userPhotoUrl.isNotEmpty
                                        ? NetworkImage(_userPhotoUrl)
                                        : null,
                                child:
                                    _userPhotoUrl.isEmpty
                                        ? Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                        )
                                        : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 9.0,
                    color: _appBarColor,
                    margin: const EdgeInsets.symmetric(vertical: 7.0),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: RiwayatCardWidget(
                        entry: widget.entry,
                        onTap: null,
                        onScreenshotTap: null,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child:
                          _isLoadingDetails
                              ? const Center(child: CircularProgressIndicator())
                              : _errorMessage.isNotEmpty
                              ? Center(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : _detailedCards.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Tidak ada detail kartu untuk riwayat ini.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: SingleChildScrollView(
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(1.5),
                                      1: FlexColumnWidth(3),
                                      2: FlexColumnWidth(3),
                                      3: FlexColumnWidth(3),
                                      4: FlexColumnWidth(2),
                                    },
                                    border: TableBorder.all(
                                      color: _tableDividerColor,
                                      width: 1.0,
                                    ),
                                    children: [
                                      TableRow(
                                        decoration: const BoxDecoration(
                                          color: _tableHeaderBgColor,
                                        ),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'No',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Model',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Runno Awal',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Runno Akhir',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'QTY',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ...List.generate(_detailedCards.length, (
                                        index,
                                      ) {
                                        final card = _detailedCards[index];
                                        final Color rowColor =
                                            index % 2 == 0
                                                ? _tableRowEvenColor
                                                : _tableRowOddColor;

                                        return TableRow(
                                          decoration: BoxDecoration(
                                            color: rowColor,
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                card.model,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                card.runnoAwal,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                card.runnoAkhir,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                card.qty,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                    ),
                  ),
                ],
              ),

              Visibility(
                visible: !_isTakingScreenshot,
                child: Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'whatsappBtn',
                        onPressed:
                            _handleWAFlow, // Memanggil flow yang sudah diperbaiki
                        backgroundColor: Colors.green,
                        child: SvgPicture.asset(
                          'assets/images/wa.svg',
                          height: 30,
                          width: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: 'screenshotBtn',
                        onPressed:
                            _takeScreenshotAndSave, // Tombol screenshot terpisah
                        backgroundColor: _appBarColor,
                        child: SvgPicture.asset(
                          'assets/images/ss.svg',
                          height: 20,
                          width: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
