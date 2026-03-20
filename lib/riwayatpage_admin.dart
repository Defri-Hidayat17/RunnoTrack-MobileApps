// lib/riwayatpage_admin.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:runnotrack/models/history_entry.dart';
// import 'package:runnotrack/admin_history_card_widget.dart'; // DIHAPUS
import 'package:runnotrack/riwayat_card_widget.dart'; // TAMBAHKAN INI
import 'package:runnotrack/tracking_entry_page.dart';
import 'package:runnotrack/screenshotpage.dart';

const String _baseUrl =
    'http://192.168.1.10/runnotrack_api'; // PASTIKAN IP INI BENAR!

class RiwayatpageAdmin extends StatefulWidget {
  const RiwayatpageAdmin({super.key});

  @override
  State<RiwayatpageAdmin> createState() => _RiwayatpageAdminState();
}

class _RiwayatpageAdminState extends State<RiwayatpageAdmin> {
  final TextEditingController _searchController = TextEditingController();
  List<HistoryEntry> _adminHistoryEntries =
      []; // Ubah tipe menjadi List<HistoryEntry>
  bool _isLoading = false;
  String _currentSearchQuery = '';

  String? _selectedProductionType; // 'KaishiPicking' atau 'Crossline'

  @override
  void initState() {
    super.initState();
    // Data akan dimuat setelah user memilih tipe produksi
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminHistoryEntries({
    String? query,
    required String productionType,
  }) async {
    setState(() {
      _isLoading = true;
    });

    String url = '$_baseUrl/get_admin_history_entries.php?';

    if (query != null && query.isNotEmpty) {
      url += 'query=${Uri.encodeComponent(query)}&';
    }
    url += 'production_type=${Uri.encodeComponent(productionType)}&';

    if (url.endsWith('&')) {
      url = url.substring(0, url.length - 1);
    }

    print('Fetching Admin History from URL: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('Admin History Response Status: ${response.statusCode}');
      print('Admin History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          List<HistoryEntry> fetchedAdminEntries = []; // Ubah tipe
          if (responseData['data'] != null && responseData['data'] is List) {
            for (var entryJson in responseData['data']) {
              fetchedAdminEntries.add(
                HistoryEntry.fromJson(entryJson),
              ); // Parse ke HistoryEntry
            }
          }
          setState(() {
            _adminHistoryEntries = fetchedAdminEntries;
          });
        } else {
          _showSnackBar(
            'Gagal memuat riwayat admin: ${responseData['message']}',
          );
          setState(() {
            _adminHistoryEntries = [];
          });
        }
      } else {
        _showSnackBar(
          'Gagal memuat riwayat admin. Status: ${response.statusCode}',
        );
        setState(() {
          _adminHistoryEntries = [];
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching admin history: $e');
      print('Error fetching admin history: $e'); // DEBUGGING
      setState(() {
        _adminHistoryEntries = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchSubmitted(String query) {
    if (_selectedProductionType == null) {
      _showSnackBar('Pilih KaishiPicking atau Crossline dulu!');
      return;
    }

    setState(() {
      _currentSearchQuery = query;
    });

    _fetchAdminHistoryEntries(
      query: query,
      productionType: _selectedProductionType!,
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelectionMade = _selectedProductionType != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedProductionType = 'KaishiPicking';
                          _adminHistoryEntries =
                              []; // Reset data saat ganti tipe
                          _currentSearchQuery = '';
                          _searchController.clear();
                        });
                        _fetchAdminHistoryEntries(
                          productionType: _selectedProductionType!,
                          query: _currentSearchQuery,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedProductionType == 'KaishiPicking'
                                ? const Color(0xFF0D2547)
                                : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'KaishiPicking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedProductionType = 'Crossline';
                          _adminHistoryEntries =
                              []; // Reset data saat ganti tipe
                          _currentSearchQuery = '';
                          _searchController.clear();
                        });
                        _fetchAdminHistoryEntries(
                          productionType: _selectedProductionType!,
                          query: _currentSearchQuery,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedProductionType == 'Crossline'
                                ? const Color(0xFF0D2547)
                                : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Crossline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                height: 55,
                decoration: BoxDecoration(
                  color:
                      isSelectionMade
                          ? const Color(0xFF03112B)
                          : Colors.grey[400],
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          left: 6,
                          top: 6,
                          bottom: 6,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _searchController,
                          enabled: isSelectionMade,
                          decoration: InputDecoration(
                            hintText: 'Cari Histori (nama/tanggal/grup)...',
                            hintStyle: TextStyle(
                              color:
                                  isSelectionMade
                                      ? Colors.grey
                                      : Colors.grey[600],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: _onSearchSubmitted,
                          onChanged: (value) {
                            if (isSelectionMade &&
                                value.isEmpty &&
                                _currentSearchQuery.isNotEmpty) {
                              _onSearchSubmitted('');
                            }
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          isSelectionMade
                              ? () => _onSearchSubmitted(_searchController.text)
                              : () => _showSnackBar(
                                'Pilih KaishiPicking atau Crossline dulu!',
                              ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.search,
                          color:
                              isSelectionMade ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFDBE6F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _adminHistoryEntries.isEmpty && isSelectionMade
                    ? const Center(
                      child: Text(
                        'Tidak ada riwayat tracking yang ditemukan untuk kriteria ini.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : _adminHistoryEntries.isEmpty && !isSelectionMade
                    ? const Center(
                      child: Text(
                        'Pilih KaishiPicking atau Crossline untuk melihat riwayat.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: _adminHistoryEntries.length,
                      itemBuilder: (context, index) {
                        final entry =
                            _adminHistoryEntries[index]; // Sudah berupa HistoryEntry

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RiwayatCardWidget(
                            // Menggunakan RiwayatCardWidget
                            entry: entry,
                            onTap: () async {
                              final HistoryEntry? updatedEntry =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TrackingEntryPage(
                                            initialEntry: entry,
                                          ),
                                    ),
                                  );

                              if (updatedEntry != null) {
                                // Refresh data setelah kembali dari TrackingEntryPage
                                _fetchAdminHistoryEntries(
                                  query: _currentSearchQuery,
                                  productionType: _selectedProductionType!,
                                );
                              }
                            },
                            onScreenshotTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ScreenshotPage(
                                        entry: entry,
                                        userName:
                                            entry
                                                .userName, // Ambil dari objek entry
                                        userPhotoUrl:
                                            entry
                                                .userPhotoUrl, // Ambil dari objek entry
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}
