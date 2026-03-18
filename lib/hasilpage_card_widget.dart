// lib/hasilpage_card_widget.dart (FINAL VERSION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

// Import CardData model
import 'package:runnotrack/models/card_data.dart';

class HasilpageCardWidget extends StatefulWidget {
  final CardData cardData;
  final BorderSide darkBlueCardBorderSide;
  final Color cardBackgroundColor;
  final bool readOnly; // True if the entire entry is confirmed (from Hasilpage)
  final Function(
    int id,
    String model,
    String runnoAwal,
    String runnoAkhir,
    String qty,
    bool hasChanges,
  )
  onDataChanged;
  final Function(int id) onSave;
  final Function(int id, String model, String runnoAwal, String runnoAkhir)?
  onDelete;

  const HasilpageCardWidget({
    Key? key,
    required this.cardData,
    required this.darkBlueCardBorderSide,
    this.cardBackgroundColor = Colors.white,
    this.readOnly = false,
    required this.onDataChanged,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<HasilpageCardWidget> createState() => _HasilpageCardWidgetState();
}

class _HasilpageCardWidgetState extends State<HasilpageCardWidget> {
  late TextEditingController _modelController;
  late TextEditingController _runnoAwalController;
  late TextEditingController _runnoAkhirController;
  late TextEditingController _qtyController;

  late CardData _initialCardData; // <-- BARU: Menyimpan snapshot data awal
  bool _isEditing = false; // Internal state for edit mode

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

    _modelController.addListener(_onChanged);
    _runnoAwalController.addListener(_onChanged);
    _runnoAkhirController.addListener(_onChanged);

    _initialCardData =
        widget.cardData.copyWith(); // <-- BARU: Inisialisasi snapshot
    _calculateQtyInternal();
  }

  // Helper untuk memeriksa perubahan lokal
  bool _hasLocalChanges() {
    // <-- PERUBAHAN: Bandingkan dengan _initialCardData
    return _modelController.text != _initialCardData.model ||
        _runnoAwalController.text != _initialCardData.runnoAwal ||
        _runnoAkhirController.text != _initialCardData.runnoAkhir ||
        _qtyController.text != _initialCardData.qty;
  }

  @override
  void didUpdateWidget(covariant HasilpageCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Perbarui controller jika cardData berubah secara eksternal (misalnya, setelah simpan/hapus atau fetch)
    // Menggunakan operator == yang di-override di CardData untuk perbandingan yang efisien
    if (oldWidget.cardData != widget.cardData) {
      // Hanya perbarui jika teks benar-benar berubah untuk menghindari cursor melompat
      if (_modelController.text != widget.cardData.model) {
        _modelController.text = widget.cardData.model;
      }
      if (_runnoAwalController.text != widget.cardData.runnoAwal) {
        _runnoAwalController.text = widget.cardData.runnoAwal;
      }
      if (_runnoAkhirController.text != widget.cardData.runnoAkhir) {
        _runnoAkhirController.text = widget.cardData.runnoAkhir;
      }

      // Hitung ulang QTY secara eksplisit berdasarkan nilai runno baru dari widget.cardData
      // dan perbarui _qtyController.
      final newRunnoAwal = int.tryParse(widget.cardData.runnoAwal);
      final newRunnoAkhir = int.tryParse(widget.cardData.runnoAkhir);
      String calculatedQty = '';
      if (newRunnoAwal != null &&
          newRunnoAkhir != null &&
          newRunnoAkhir >= newRunnoAwal) {
        calculatedQty = (newRunnoAkhir - newRunnoAwal + 1).toString();
      }
      if (_qtyController.text != calculatedQty) {
        _qtyController.text = calculatedQty;
      }

      // Jika data diperbarui secara eksternal (misalnya, setelah simpan atau fetch),
      // dan parent menunjukkan tidak ada perubahan, keluar dari mode edit.
      // Ini penting agar setelah save, tombol kembali menjadi edit.
      // <-- PERUBAHAN: Reset _initialCardData dan _isEditing saat data diperbarui dari parent
      if (!widget.cardData.hasChanges) {
        setState(() {
          _initialCardData =
              widget.cardData.copyWith(); // Reset snapshot ke data terbaru
          _isEditing = false; // Keluar dari mode edit
        });
      }
    }
  }

  @override
  void dispose() {
    _modelController.removeListener(_onChanged);
    _runnoAwalController.removeListener(_onChanged);
    _runnoAkhirController.removeListener(_onChanged);
    _modelController.dispose();
    _runnoAwalController.dispose();
    _runnoAkhirController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // Internal function to calculate QTY without triggering _onChanged recursively
  void _calculateQtyInternal() {
    final runnoAwal = int.tryParse(_runnoAwalController.text);
    final runnoAkhir = int.tryParse(_runnoAkhirController.text);

    if (runnoAwal != null && runnoAkhir != null && runnoAkhir >= runnoAwal) {
      final qty = runnoAkhir - runnoAwal + 1;
      // Hanya perbarui _qtyController.text jika berbeda untuk menghindari rebuild yang tidak perlu
      if (_qtyController.text != qty.toString()) {
        _qtyController.text = qty.toString();
      }
    } else {
      if (_qtyController.text != '') {
        _qtyController.text = '';
      }
    }
  }

  void _onChanged() {
    // Hitung ulang QTY jika runnoAwal atau runnoAkhir berubah
    // Ini perlu dilakukan sebelum memeriksa hasChanges berdasarkan _qtyController.text
    _calculateQtyInternal();

    final currentModel = _modelController.text;
    final currentRunnoAwal = _runnoAwalController.text;
    final currentRunnoAkhir = _runnoAkhirController.text;
    final currentQty =
        _qtyController.text; // Sekarang ini akan mencerminkan QTY yang dihitung

    final hasChanges =
        _hasLocalChanges(); // Gunakan _hasLocalChanges yang sudah diperbaiki

    // SELALU panggil onDataChanged untuk memberi tahu parent tentang keadaan kartu saat ini.
    // Parent akan memutuskan apakah setState diperlukan berdasarkan perbandingannya sendiri.
    widget.onDataChanged(
      widget.cardData.id,
      currentModel,
      currentRunnoAwal,
      currentRunnoAkhir,
      currentQty,
      hasChanges, // Teruskan status hasChanges yang dihitung
    );
  }

  // Re-using the _buildInputDecoration from dynamic_card.dart as a base
  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    TextAlign textAlign = TextAlign.start,
    BorderSide? inputBorderSide,
    FloatingLabelAlignment floatingLabelAlignment =
        FloatingLabelAlignment.start,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool isReadOnly =
        false, // New parameter to adjust decoration for read-only state
  }) {
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
      filled: isReadOnly, // Fill background only if read-only
      fillColor:
          isReadOnly
              ? Colors.grey[100]
              : Colors.white, // Light grey for read-only
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      isDense: true,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If the entire entry is readOnly (e.g., confirmed), then this card cannot be edited
    final bool isEntryConfirmed = widget.readOnly;
    final bool isCurrentlyEditable = !isEntryConfirmed && _isEditing;

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Minimal vertical margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: widget.darkBlueCardBorderSide,
      ),
      elevation: 2,
      color: widget.cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced overall card padding
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch fields horizontally
          mainAxisSize: MainAxisSize.min, // Crucial for preventing overflow
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${widget.cardData.id}',
                  style: const TextStyle(
                    fontSize: 15, // Smaller font for card title
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2547),
                  ),
                ),
                if (!isEntryConfirmed) // Only show action buttons if entry is not confirmed
                  _buildActionButtons(isCurrentlyEditable),
              ],
            ),
            const SizedBox(height: 10), // Space after title/buttons
            // Model field
            _buildDataField(
              label: 'Model',
              controller: _modelController,
              isEditable: isCurrentlyEditable,
            ),
            const SizedBox(height: 10), // Spacing between fields
            // Runno Awal and Runno Akhir in a Row
            Row(
              children: [
                Expanded(
                  child: _buildDataField(
                    label: 'Runno Awal',
                    controller: _runnoAwalController,
                    isEditable: isCurrentlyEditable,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 10), // Horizontal space
                Expanded(
                  child: _buildDataField(
                    label: 'Runno Akhir',
                    controller: _runnoAkhirController,
                    isEditable: isCurrentlyEditable,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Spacing between fields
            // QTY field (always read-only)
            _buildDataField(
              label: 'QTY',
              controller: _qtyController,
              isEditable: false, // QTY is always read-only as it's calculated
              isQtyField: true, // Special flag for QTY field
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isCurrentlyEditable) {
    if (isCurrentlyEditable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed:
                widget
                        .cardData
                        .hasChanges // Save button enabled only if there are changes
                    ? () {
                      widget.onSave(widget.cardData.id);
                      // didUpdateWidget akan menangani _isEditing = false setelah data fetch
                    }
                    : null,
            icon: Icon(
              Icons.save,
              color: widget.cardData.hasChanges ? Colors.green : Colors.grey,
              size: 20,
            ),
            tooltip: 'Save Changes',
            padding: EdgeInsets.zero, // Remove default padding
            constraints: const BoxConstraints(), // Remove default constraints
          ),
          if (widget.onDelete != null)
            IconButton(
              onPressed: () async {
                final bool? confirmed = await showDialog<bool>(
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
                );
                if (confirmed == true) {
                  widget.onDelete!(
                    widget.cardData.id,
                    _modelController.text,
                    _runnoAwalController.text,
                    _runnoAkhirController.text,
                  );
                  // didUpdateWidget akan menangani _isEditing = false setelah data fetch
                }
              },
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: 'Delete Card',
              padding: EdgeInsets.zero, // Remove default padding
              constraints: const BoxConstraints(), // Remove default constraints
            ),
        ],
      );
    } else {
      // Not editing, show edit button
      return IconButton(
        onPressed: () {
          setState(() {
            _isEditing = true;
            // <-- PERUBAHAN: Set _initialCardData saat masuk mode edit
            _initialCardData = widget.cardData.copyWith();
          });
        },
        icon: const Icon(Icons.edit, color: Color(0xFF0D2547), size: 20),
        tooltip: 'Edit Card',
        padding: EdgeInsets.zero, // Remove default padding
        constraints: const BoxConstraints(), // Remove default constraints
      );
    }
  }

  Widget _buildDataField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isQtyField = false, // Special handling for QTY field
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !isEditable || isQtyField, // QTY is always read-only
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: (!isEditable || isQtyField) ? Colors.grey[700] : Colors.black87,
        fontSize: 14,
      ),
      decoration: _buildInputDecoration(
        labelText: label,
        inputBorderSide: widget.darkBlueCardBorderSide,
        isReadOnly:
            !isEditable || isQtyField, // Pass read-only state to decoration
      ),
    );
  }
}
