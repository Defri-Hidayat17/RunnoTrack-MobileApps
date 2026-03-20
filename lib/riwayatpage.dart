// lib/riwayatpage.dart (FINAL VERSION - CORRECTED)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:runnotrack/models/history_entry.dart';
import 'package:runnotrack/riwayat_card_widget.dart';
import 'package:runnotrack/tracking_entry_page.dart'; // Pastikan ini mengarah ke TrackingEntryPage
import 'package:runnotrack/screenshotpage.dart'; // Import halaman screenshot Anda

const String _baseUrl = 'http://192.168.1.10/runnotrack_api';

class Riwayatpage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;

  const Riwayatpage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
  });

  @override
  State<Riwayatpage> createState() => _RiwayatpageState();
}

class _RiwayatpageState extends State<Riwayatpage> {
  final TextEditingController _searchController = TextEditingController();
  List<HistoryEntry> _historyEntries = [];
  bool _isLoading = false;
  String _currentSearchQuery = '';
  bool _hasSearched = false; // Reintroduce this flag

  late String _userName;
  late String _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userPhotoUrl = widget.userPhotoUrl;
    // _fetchHistoryEntries() TIDAK DIPANGGIL di initState agar data tidak muncul saat awal
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistoryEntries({String? query}) async {
    setState(() {
      _isLoading = true;
    });

    String url = '$_baseUrl/get_history_entries.php?user_id=${widget.userId}';

    if (query != null && query.isNotEmpty) {
      url += '&query=${Uri.encodeComponent(query)}';
    }

    print('Fetching User History from URL: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('User History Response Status: ${response.statusCode}');
      print('User History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          List<HistoryEntry> fetchedEntries = [];
          if (responseData['data'] != null && responseData['data'] is List) {
            for (var entryJson in responseData['data']) {
              fetchedEntries.add(HistoryEntry.fromJson(entryJson));
            }
          }
          setState(() {
            _historyEntries = fetchedEntries;
          });
        } else {
          _showSnackBar('Gagal memuat riwayat: ${responseData['message']}');
          setState(() {
            _historyEntries = [];
          });
        }
      } else {
        _showSnackBar('Gagal memuat riwayat. Status: ${response.statusCode}');
        setState(() {
          _historyEntries = [];
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching history: $e');
      print('Error fetching user history: $e'); // DEBUGGING
      setState(() {
        _historyEntries = [];
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
    setState(() {
      _currentSearchQuery = query;
      _hasSearched = true; // Menandakan bahwa pencarian telah dilakukan
    });

    if (query.isEmpty) {
      // Jika query kosong, kosongkan daftar dan jangan panggil fetch
      setState(() {
        _historyEntries = [];
      });
    } else {
      // Jika query tidak kosong, panggil fetch
      _fetchHistoryEntries(query: query);
    }
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF03112B),
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
                    margin: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari Histori (nama/tanggal)...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _onSearchSubmitted,
                      onChanged: (value) {
                        // Jika search bar dikosongkan setelah ada pencarian,
                        // panggil _onSearchSubmitted dengan query kosong
                        if (value.isEmpty && _currentSearchQuery.isNotEmpty) {
                          _onSearchSubmitted('');
                        }
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _onSearchSubmitted(_searchController.text),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
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
                    : !_hasSearched
                    ? const Center(
                      child: Text(
                        'Silakan cari nama atau tanggal untuk melihat riwayat.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : _historyEntries.isEmpty
                    ? const Center(
                      child: Text(
                        'Tidak ada riwayat tracking yang ditemukan.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: _historyEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _historyEntries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RiwayatCardWidget(
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
                                final int entryIndex = _historyEntries
                                    .indexWhere((e) => e.id == updatedEntry.id);
                                if (entryIndex != -1) {
                                  setState(() {
                                    _historyEntries[entryIndex] = updatedEntry;
                                  });
                                }
                              } else {
                                // Refresh data setelah kembali dari halaman detail
                                // Jika _currentSearchQuery kosong, ini akan mengosongkan list.
                                // Jika _currentSearchQuery tidak kosong, ini akan memuat ulang hasil pencarian.
                                _fetchHistoryEntries(
                                  query: _currentSearchQuery,
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
                                        userName: _userName,
                                        userPhotoUrl: _userPhotoUrl,
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
