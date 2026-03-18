// lib/dynamic_card.dart

import 'package:flutter/material.dart';
import 'dart:convert'; // Masih diperlukan untuk _parseQrCode
import 'package:permission_handler/permission_handler.dart'; // Import untuk izin kamera
import 'package:runnotrack/qr_scanner_page.dart'; // Import halaman scanner yang baru dibuat

// Import CardData dari file yang baru dibuat
import 'package:runnotrack/models/card_data.dart';

/// Widget Card Dinamis yang menampilkan input field untuk Model, Runno, dan QTY.
class DynamicCard extends StatefulWidget {
  final CardData cardData;
  // Perbarui callback onDataChanged untuk menerima parameter hasChanges
  final Function(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
    String qty,
    bool hasChanges, // <--- BARIS INI DITAMBAHKAN
  )
  onDataChanged;
  final Function(int id) onSave;
  final BorderSide
  darkBlueCardBorderSide; // Ini adalah properti yang akan digunakan
  final Color cardBackgroundColor;
  final bool readOnly;

  const DynamicCard({
    super.key,
    required this.cardData,
    required this.onDataChanged,
    required this.onSave,
    required this.darkBlueCardBorderSide, // Ini adalah properti yang akan digunakan
    required this.cardBackgroundColor,
    this.readOnly = false,
  });

  @override
  State<DynamicCard> createState() => _DynamicCardState();
}

class _DynamicCardState extends State<DynamicCard> {
  late TextEditingController _modelController;
  late TextEditingController _runnoAwalController;
  late TextEditingController _runnoAkhirController;
  late TextEditingController _qtyController;

  bool _isModelAndRunnoAwalScanned = false;
  bool _isUpdatingFromParent = false;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.cardData.model);
    _runnoAwalController = TextEditingController(
      text: widget.cardData.runnoAwal,
    );
    _runnoAkhirController = TextEditingController(
      text: widget.cardData.runnoAkhir,
    );
    _qtyController = TextEditingController(text: widget.cardData.qty);

    if (!widget.readOnly) {
      _modelController.addListener(_onChanged);
      _runnoAwalController.addListener(_onChanged);
      _runnoAkhirController.addListener(_onChanged);
    }
    _calculateQty();
  }

  @override
  void didUpdateWidget(covariant DynamicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hanya perbarui jika cardData itu sendiri telah berubah, atau jika status readOnly berubah
    if (widget.cardData.id != oldWidget.cardData.id ||
        widget.cardData.model != oldWidget.cardData.model ||
        widget.cardData.runnoAwal != oldWidget.cardData.runnoAwal ||
        widget.cardData.runnoAkhir != oldWidget.cardData.runnoAkhir ||
        widget.cardData.qty != oldWidget.cardData.qty ||
        widget.readOnly != oldWidget.readOnly) {
      _isUpdatingFromParent =
          true; // Mencegah _onChanged terpicu karena pembaruan controller internal

      // Perbarui controller jika data dari widget.cardData berbeda
      // Ini penting untuk memastikan field teks mencerminkan cardData terbaru
      if (_modelController.text != widget.cardData.model) {
        _modelController.text = widget.cardData.model;
      }
      if (_runnoAwalController.text != widget.cardData.runnoAwal) {
        _runnoAwalController.text = widget.cardData.runnoAwal;
      }
      if (_runnoAkhirController.text != widget.cardData.runnoAkhir) {
        _runnoAkhirController.text = widget.cardData.runnoAkhir;
      }
      if (_qtyController.text != widget.cardData.qty) {
        _qtyController.text = widget.cardData.qty;
      }

      _calculateQty(); // Hitung ulang QTY jika ada runno yang berubah

      // Reset status scan jika ID kartu berubah, yang berarti itu adalah kartu baru
      if (widget.cardData.id != oldWidget.cardData.id) {
        _isModelAndRunnoAwalScanned = false;
      }

      // Tangani perubahan listener berdasarkan status readOnly
      if (widget.readOnly && !oldWidget.readOnly) {
        _modelController.removeListener(_onChanged);
        _runnoAwalController.removeListener(_onChanged);
        _runnoAkhirController.removeListener(_onChanged);
      } else if (!widget.readOnly && oldWidget.readOnly) {
        _modelController.addListener(_onChanged);
        _runnoAwalController.addListener(_onChanged);
        _runnoAkhirController.addListener(_onChanged);
      }

      _isUpdatingFromParent = false; // Izinkan _onChanged untuk terpicu lagi
    }
  }

  @override
  void dispose() {
    if (!widget.readOnly) {
      _modelController.removeListener(_onChanged);
      _runnoAwalController.removeListener(_onChanged);
      _runnoAkhirController.removeListener(_onChanged);
    }
    _modelController.dispose();
    _runnoAwalController.dispose();
    _runnoAkhirController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_isUpdatingFromParent || widget.readOnly) return;

    _calculateQty();
    widget.onDataChanged(
      widget.cardData.id,
      _modelController.text,
      _runnoAwalController.text,
      _runnoAkhirController.text,
      _qtyController.text,
      true, // <--- INI PENTING: Set hasChanges ke TRUE saat ada perubahan
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    TextAlign textAlign = TextAlign.start,
    BorderSide? inputBorderSide,
    FloatingLabelAlignment floatingLabelAlignment =
        FloatingLabelAlignment.start,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool autoBalancePrefixIcon = false,
  }) {
    Widget? effectivePrefixIcon = prefixIcon;

    if (autoBalancePrefixIcon && suffixIcon != null && prefixIcon == null) {
      effectivePrefixIcon = const SizedBox(width: 48.0);
    }

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: floatingLabelAlignment,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: inputBorderSide ?? BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: inputBorderSide?.color ?? Colors.blue,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: inputBorderSide ?? BorderSide.none,
      ),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      isDense: true,
      suffixIcon: suffixIcon,
      prefixIcon: effectivePrefixIcon,
    );
  }

  Future<String?> _scanQrOrBarcode(BuildContext context) async {
    if (widget.readOnly) return null;

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin kamera ditolak. Tidak dapat memindai.'),
          ),
        );
        return null;
      }
    }

    if (!mounted) return null;
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );

    return scannedData as String?;
  }

  Map<String, String> _parseQrCode(String qrData) {
    String model = '';
    String runno = '';

    final normalizedQrData = qrData.toUpperCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final parts =
        normalizedQrData.split(' ').where((s) => s.isNotEmpty).toList();

    String? rawRunnoNumberCandidate;
    for (var part in parts) {
      if (RegExp(r'^\d{8,}$').hasMatch(part)) {
        rawRunnoNumberCandidate = part;
        break;
      }
    }

    if (rawRunnoNumberCandidate != null) {
      if (rawRunnoNumberCandidate.length >= 5) {
        runno = rawRunnoNumberCandidate.substring(
          rawRunnoNumberCandidate.length - 5,
        );
      } else if (rawRunnoNumberCandidate.length >= 4) {
        runno = rawRunnoNumberCandidate;
      }
    } else {
      for (var part in parts) {
        if (RegExp(r'^\d{4,5}$').hasMatch(part)) {
          runno = part;
          break;
        }
      }
    }

    final specificModelPattern = RegExp(r'\b([A-Z]{3}\d{2})\b');
    final specificModelMatch = specificModelPattern.firstMatch(
      normalizedQrData,
    );
    if (specificModelMatch != null && specificModelMatch.group(1) != null) {
      model = specificModelMatch.group(1)!;
    } else {
      String? modelCandidateFromYV;
      for (var part in parts) {
        if (part.contains('YV') && part.length >= 5) {
          modelCandidateFromYV = part;
          break;
        }
      }

      if (modelCandidateFromYV != null) {
        String potentialModel = modelCandidateFromYV.split('YV')[0];
        if (potentialModel.length >= 3 &&
            RegExp(r'[A-Z]').hasMatch(potentialModel)) {
          model = potentialModel;
        }
      }

      if (model.isEmpty) {
        for (var part in parts) {
          if (RegExp(r'^\d+$').hasMatch(part)) {
            continue;
          }
          if (part.length >= 3 &&
              part.length <= 15 &&
              RegExp(r'[A-Z]').hasMatch(part)) {
            model = part;
            break;
          }
        }
      }
    }

    return {'model': model, 'runno': runno};
  }

  void _handleModelAndRunnoAwalScan() async {
    if (widget.readOnly) return;
    final scannedData = await _scanQrOrBarcode(context);
    if (scannedData != null) {
      final parsed = _parseQrCode(scannedData);
      setState(() {
        _modelController.text = parsed['model'] ?? '';
        _runnoAwalController.text = parsed['runno'] ?? '';
        _isModelAndRunnoAwalScanned = true;
        _runnoAkhirController.clear();
        _onChanged(); // Panggil _onChanged untuk memicu update hasChanges
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan dibatalkan atau gagal.')),
      );
    }
  }

  void _handleRunnoAwalScan() async {
    if (widget.readOnly) return;
    final scannedData = await _scanQrOrBarcode(context);
    if (scannedData != null) {
      final parsed = _parseQrCode(scannedData);
      setState(() {
        _runnoAwalController.text = parsed['runno'] ?? '';
        _onChanged(); // Panggil _onChanged untuk memicu update hasChanges
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan dibatalkan atau gagal.')),
      );
    }
  }

  void _handleRunnoAkhirScan() async {
    if (widget.readOnly) return;
    final scannedData = await _scanQrOrBarcode(context);
    if (scannedData != null) {
      final parsed = _parseQrCode(scannedData);
      setState(() {
        _runnoAkhirController.text = parsed['runno'] ?? '';
        _onChanged(); // Panggil _onChanged untuk memicu update hasChanges
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan dibatalkan atau gagal.')),
      );
    }
  }

  void _calculateQty() {
    final runnoAwal = int.tryParse(_runnoAwalController.text);
    final runnoAkhir = int.tryParse(_runnoAkhirController.text);

    if (runnoAwal != null && runnoAkhir != null && runnoAkhir >= runnoAwal) {
      final qty = runnoAkhir - runnoAwal + 1;
      _qtyController.text = qty.toString();
    } else {
      _qtyController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi BorderSide lokal dihapus karena sudah ada di properti widget

    return Card(
      color: widget.cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6.0,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 60,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF0D2547),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.cardData.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _modelController,
                  textAlign: TextAlign.center,
                  readOnly: widget.readOnly || _isModelAndRunnoAwalScanned,
                  decoration: _buildInputDecoration(
                    labelText: 'Model',
                    inputBorderSide:
                        widget
                            .darkBlueCardBorderSide, // Menggunakan properti widget
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    suffixIcon:
                        widget.readOnly
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () => _handleModelAndRunnoAwalScan(),
                            ),
                    autoBalancePrefixIcon: true,
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 2, color: const Color(0xFFDBE6F2)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _runnoAwalController,
                        readOnly:
                            widget.readOnly || _isModelAndRunnoAwalScanned,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.start,
                        decoration: _buildInputDecoration(
                          labelText: 'Runno Awal',
                          inputBorderSide:
                              widget
                                  .darkBlueCardBorderSide, // Menggunakan properti widget
                          suffixIcon:
                              widget.readOnly || _isModelAndRunnoAwalScanned
                                  ? null
                                  : IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () => _handleRunnoAwalScan(),
                                  ),
                          autoBalancePrefixIcon: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _runnoAkhirController,
                        readOnly: widget.readOnly,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.start,
                        decoration: _buildInputDecoration(
                          labelText: 'Runno Akhir',
                          inputBorderSide:
                              widget
                                  .darkBlueCardBorderSide, // Menggunakan properti widget
                          suffixIcon:
                              widget.readOnly
                                  ? null
                                  : IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () => _handleRunnoAkhirScan(),
                                  ),
                          autoBalancePrefixIcon: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  textAlign: TextAlign.center,
                  decoration: _buildInputDecoration(
                    labelText: 'QTY',
                    inputBorderSide:
                        widget
                            .darkBlueCardBorderSide, // Menggunakan properti widget
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    autoBalancePrefixIcon: false,
                  ),
                ),
                if (!widget.readOnly && widget.cardData.hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onSave(widget.cardData.id),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0085AA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
