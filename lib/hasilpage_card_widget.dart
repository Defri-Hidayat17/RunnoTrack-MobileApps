// lib/hasilpage_card_widget.dart (FINAL REVISED VERSION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

// Import CardData model
import 'package:runnotrack/models/card_data.dart';

class HasilpageCardWidget extends StatefulWidget {
  final CardData cardData;
  final BorderSide darkBlueCardBorderSide; // This might become obsolete
  final Color cardBackgroundColor;
  final bool readOnly; // True if the entire entry is confirmed (from Hasilpage)

  // Callback untuk memberitahu parent bahwa data di card ini berubah
  // Parent akan menggunakan ini untuk memperbarui list CardData di state-nya
  final Function(int localId, CardData updatedCardData) onCardDataChanged;

  // Callback untuk menyimpan perubahan ke backend (UPDATE)
  // Ini akan menerima objek CardData lengkap, termasuk cardDetailId
  final Future<void> Function(CardData cardToSave) onSaveUpdatedCard;

  // Callback untuk menghapus kartu dari backend
  // Ini akan menerima cardDetailId yang benar
  final Future<void> Function(int cardDetailId)
  onDeleteCard; // <--- Tipe parameter di sini adalah 'int' (non-nullable)

  const HasilpageCardWidget({
    Key? key,
    required this.cardData,
    required this.darkBlueCardBorderSide,
    this.cardBackgroundColor = Colors.white,
    this.readOnly = false,
    required this.onCardDataChanged,
    required this.onSaveUpdatedCard,
    required this.onDeleteCard,
  }) : super(key: key);

  @override
  State<HasilpageCardWidget> createState() => _HasilpageCardWidgetState();
}

class _HasilpageCardWidgetState extends State<HasilpageCardWidget> {
  late TextEditingController _modelController;
  late TextEditingController _runnoAwalController;
  late TextEditingController _runnoAkhirController;
  late TextEditingController _qtyController;

  late CardData _initialCardData; // Snapshot of data when entering edit mode
  bool _isEditing = false; // Internal state for edit mode

  // New: Modern 3D shadow for the card
  static const List<BoxShadow> _modernCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0.5,
    ),
  ];

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

    _initialCardData = widget.cardData.copyWith(); // Initialize snapshot
    _calculateQtyInternal();
  }

  @override
  void didUpdateWidget(covariant HasilpageCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the cardData object itself has changed (e.g., new instance from parent)
    if (oldWidget.cardData != widget.cardData) {
      // Update controllers if the text content from the new cardData is different
      if (_modelController.text != widget.cardData.model) {
        _modelController.text = widget.cardData.model;
      }
      if (_runnoAwalController.text != widget.cardData.runnoAwal) {
        _runnoAwalController.text = widget.cardData.runnoAwal;
      }
      if (_runnoAkhirController.text != widget.cardData.runnoAkhir) {
        _runnoAkhirController.text = widget.cardData.runnoAkhir;
      }

      // Recalculate QTY based on new runno values from widget.cardData
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

      // --- LOGIKA BARU UNTUK shouldResetEditMode ---
      if (widget.cardData.shouldResetEditMode) {
        debugPrint(
          'Card ID ${widget.cardData.id}: Menerima sinyal shouldResetEditMode. Mereset mode edit.',
        );
        setState(() {
          _isEditing = false; // Keluar dari mode edit
          _initialCardData = widget.cardData.copyWith(
            shouldResetEditMode: false,
          ); // Reset snapshot, konsumsi sinyal
        });
        // Beri tahu parent bahwa sinyal telah dikonsumsi
        widget.onCardDataChanged(
          widget.cardData.id,
          widget.cardData.copyWith(shouldResetEditMode: false),
        );
      } else if (!widget.cardData.hasChanges && _isEditing) {
        // Jika pembaruan eksternal menunjukkan tidak ada perubahan dan kita masih dalam mode edit,
        // itu berarti perubahan telah disimpan atau dikembalikan secara eksternal (misalnya, _fetchTrackingResults).
        setState(() {
          _initialCardData =
              widget.cardData.copyWith(); // Reset snapshot ke data terbaru
          _isEditing = false; // Keluar dari mode edit
        });
      }
      // --- AKHIR LOGIKA BARU ---
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

  void _calculateQtyInternal() {
    final runnoAwal = int.tryParse(_runnoAwalController.text);
    final runnoAkhir = int.tryParse(_runnoAkhirController.text);

    if (runnoAwal != null && runnoAkhir != null && runnoAkhir >= runnoAwal) {
      final qty = runnoAkhir - runnoAwal + 1;
      if (_qtyController.text != qty.toString()) {
        _qtyController.text = qty.toString();
      }
    } else {
      if (_qtyController.text != '') {
        _qtyController.text = '';
      }
    }
  }

  // Helper untuk memeriksa perubahan lokal
  bool _hasLocalChanges() {
    return _modelController.text != _initialCardData.model ||
        _runnoAwalController.text != _initialCardData.runnoAwal ||
        _runnoAkhirController.text != _initialCardData.runnoAkhir ||
        _qtyController.text != _initialCardData.qty;
  }

  void _onChanged() {
    _calculateQtyInternal();

    // Buat objek CardData sementara dengan nilai-nilai controller saat ini
    // dan status hasChanges yang dihitung.
    final currentCardData = widget.cardData.copyWith(
      model: _modelController.text,
      runnoAwal: _runnoAwalController.text,
      runnoAkhir: _runnoAkhirController.text,
      qty: _qtyController.text,
      hasChanges:
          _hasLocalChanges(), // Update hasChanges based on actual local changes
      shouldResetEditMode:
          false, // Pastikan ini false saat perubahan dibuat oleh pengguna
    );

    // Memberitahu parent tentang perubahan data di card ini
    widget.onCardDataChanged(widget.cardData.id, currentCardData);
  }

  // New: Function to revert changes
  void _revertChanges() {
    setState(() {
      _modelController.text = _initialCardData.model;
      _runnoAwalController.text = _initialCardData.runnoAwal;
      _runnoAkhirController.text = _initialCardData.runnoAkhir;
      _qtyController.text = _initialCardData.qty; // QTY should also revert
      _isEditing = false;
      // Also notify parent that changes are reverted, so hasChanges can be false
      widget.onCardDataChanged(
        widget.cardData.id,
        _initialCardData.copyWith(
          hasChanges: false,
          shouldResetEditMode: false,
        ), // Send initial data with hasChanges: false
      );
    });
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    TextAlign textAlign = TextAlign.start,
    BorderSide? inputBorderSide, // This is widget.darkBlueCardBorderSide
    FloatingLabelAlignment floatingLabelAlignment =
        FloatingLabelAlignment.start,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool isFieldReadOnly =
        false, // True if the TextFormField's readOnly property is true
    Color? customFillColor, // For QTY, this will be Colors.white
    BorderSide? customBorderSide, // For QTY, this will be blueGrey
  }) {
    // Determine the border for editable fields when not focused
    final editableBorder = BorderSide(
      color: inputBorderSide?.color ?? Colors.blue,
      width: 1.0, // Default width for editable fields when not focused
    );

    // Determine the focused border for editable fields
    final focusedEditableBorder = BorderSide(
      color: inputBorderSide?.color ?? Colors.blue,
      width: 2.0, // Thicker width for focused editable fields
    );

    // Determine the border for read-only fields (subtle grey)
    final readOnlyBorder = BorderSide(
      color: Colors.grey[400]!, // Subtle grey border for read-only
      width: 1.0,
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelAlignment: floatingLabelAlignment,
      filled: true,
      fillColor:
          customFillColor ??
          Colors
              .white, // Always white by default unless customFillColor is given
      // General border (used when no specific state border is defined)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            customBorderSide ??
            (isFieldReadOnly ? readOnlyBorder : editableBorder),
      ),
      // Border when the field is enabled but not focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            customBorderSide ??
            (isFieldReadOnly ? readOnlyBorder : editableBorder),
      ),
      // Border when the field is focused
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            customBorderSide ??
            (isFieldReadOnly ? readOnlyBorder : focusedEditableBorder),
      ),
      // Border when the field is disabled (e.g., readOnly: true)
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            customBorderSide ??
            readOnlyBorder, // Disabled should look like read-only
      ),

      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      isDense: true,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  Widget _buildActionButton({
    Key? key,
    required IconData icon,
    required Color
    iconColor, // Mengubah nama parameter untuk menghindari konflik
    required String tooltip,
    required VoidCallback? onPressed,
    double circleSize = 35.0, // Ukuran lingkaran default
    double iconSize = 18.0, // Ukuran ikon default
    Color circleBackgroundColor = const Color(
      0xFF0D2547,
    ), // Warna background lingkaran default
    Color? circleBorderColor, // Warna border lingkaran opsional
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ), // Spasi antar tombol diperkecil
      width: circleSize, // Kontrol ukuran lingkaran secara eksplisit
      height: circleSize, // Kontrol ukuran lingkaran secara eksplisit
      decoration: BoxDecoration(
        color: circleBackgroundColor, // Gunakan warna background lingkaran
        shape: BoxShape.circle,
        border:
            circleBorderColor != null
                ? Border.all(color: circleBorderColor, width: 1.0)
                : null, // Tambahkan border jika ada
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: iconSize), // Gunakan iconColor
        tooltip: tooltip,
        padding: EdgeInsets.zero, // Hapus padding default IconButton
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEntryConfirmed = widget.readOnly;
    final bool isCurrentlyEditable = !isEntryConfirmed && _isEditing;

    // Debugging readOnly state
    debugPrint(
      'Card ID ${widget.cardData.id}: isEntryConfirmed=$isEntryConfirmed, _isEditing=$_isEditing, isCurrentlyEditable=$isCurrentlyEditable',
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Radius card utama
      ),
      elevation: 0,
      color: widget.cardBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20), // Radius container utama
          boxShadow: _modernCardShadow,
        ),
        child: Padding(
          // Padding disesuaikan untuk menghilangkan space bawah dan mengatur top
          padding: const EdgeInsets.fromLTRB(
            10.0,
            10.0,
            10.0,
            10.0, // Padding bawah dikembalikan ke 10.0 agar tidak terlalu mepet
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Pertahankan ini untuk Column
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Nomor Urutan (menggunakan cardData.cardDetailId)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2547), // Dark blue background
                      borderRadius: BorderRadius.circular(5), // Radius badge
                    ),
                    child: Text(
                      '${widget.cardData.cardDetailId ?? 'N/A'}', // <--- MENGGUNAKAN cardDetailId, dengan fallback 'N/A'
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for contrast
                      ),
                    ),
                  ),

                  // Tombol Aksi (tanpa AnimatedSwitcher)
                  if (!isEntryConfirmed)
                    isCurrentlyEditable
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: Icons.delete,
                              iconColor: const Color.fromARGB(
                                255,
                                255,
                                17,
                                0,
                              ), // Warna ikon merah
                              circleBackgroundColor:
                                  Colors.white, // Background lingkaran putih
                              circleBorderColor: Colors.black, // Stroke hitam
                              tooltip: 'Delete Card',
                              onPressed: () async {
                                FocusScope.of(
                                  context,
                                ).unfocus(); // TUTUP KEYBOARD
                                final bool? confirmed = await showDialog<bool>(
                                  context: context,
                                  barrierColor: Colors.black.withOpacity(
                                    0.8,
                                  ), // Latar belakang gelap
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor:
                                          Colors
                                              .white, // Kartu konfirmasi tetap putih
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          25,
                                        ), // Sudut membulat modern
                                      ),
                                      title: const Text(
                                        'Konfirmasi Hapus',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ), // Judul tebal
                                      ),
                                      content: const Text(
                                        'Apakah Anda yakin ingin menghapus data ini?',
                                        style: TextStyle(
                                          fontSize: 13,
                                        ), // Ukuran teks konten sedikit lebih besar
                                      ),
                                      actions: <Widget>[
                                        // Tombol "Batal"
                                        OutlinedButton(
                                          // Dibungkus box modern
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFF0D2547),
                                              width: 1.5,
                                            ), // Border biru tua
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Batal',
                                            style: TextStyle(
                                              color: Color(0xFF0D2547),
                                              fontSize: 13,
                                            ), // Teks biru tua
                                          ),
                                        ),
                                        // Tombol "Hapus"
                                        ElevatedButton(
                                          // Dibungkus box modern
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors
                                                    .red, // Latar belakang merah
                                            foregroundColor:
                                                Colors.white, // Teks putih
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Hapus',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                      actionsAlignment:
                                          MainAxisAlignment
                                              .end, // Tombol rata kanan
                                    );
                                  },
                                );
                                if (confirmed == true) {
                                  if (widget.cardData.cardDetailId != null) {
                                    await widget.onDeleteCard(
                                      widget.cardData.cardDetailId!,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Kartu ini belum tersimpan. Silakan batalkan atau hapus dari daftar.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.save,
                              iconColor:
                                  widget.cardData.hasChanges
                                      ? const Color.fromARGB(255, 255, 255, 255)
                                      : Colors
                                          .grey, // Warna abu-abu jika tidak ada perubahan
                              tooltip: 'Save Changes',
                              onPressed:
                                  widget.cardData.hasChanges
                                      ? () async {
                                        FocusScope.of(
                                          context,
                                        ).unfocus(); // TUTUP KEYBOARD
                                        final cardToSave = widget.cardData.copyWith(
                                          model: _modelController.text,
                                          runnoAwal: _runnoAwalController.text,
                                          runnoAkhir:
                                              _runnoAkhirController.text,
                                          qty: _qtyController.text,
                                          hasChanges: false,
                                          shouldResetEditMode:
                                              false, // Dikirim false, parent akan set true setelah berhasil
                                        );
                                        await widget.onSaveUpdatedCard(
                                          cardToSave,
                                        );
                                      }
                                      : null, // Nonaktifkan tombol jika tidak ada perubahan
                            ),
                            _buildActionButton(
                              icon: Icons.close,
                              iconColor: const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                              tooltip: 'Cancel Edit',
                              onPressed: () {
                                FocusScope.of(
                                  context,
                                ).unfocus(); // TUTUP KEYBOARD
                                _revertChanges();
                              },
                            ),
                          ],
                        )
                        : _buildActionButton(
                          icon: Icons.edit,
                          iconColor: const Color.fromARGB(255, 255, 255, 255),
                          tooltip: 'Edit Card',
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                              _initialCardData = widget.cardData.copyWith();
                            });
                          },
                        ),
                ],
              ),
              const SizedBox(height: 16), // Jarak dikurangi
              // Baris baru untuk Model dan QTY
              Row(
                children: [
                  Expanded(
                    child: _buildDataField(
                      label: 'Model',
                      controller: _modelController,
                      isEditable: isCurrentlyEditable,
                      textAlign: TextAlign.center,
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      customFillColor: Colors.white, // Pastikan putih
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDataField(
                      label: 'QTY',
                      controller: _qtyController,
                      isEditable: false, // QTY is never directly editable
                      isQtyField: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      customFillColor: Colors.white, // Pastikan putih
                      customBorderSide: const BorderSide(
                        color: Colors.blueGrey,
                        width: 1.5,
                      ), // Border khusus
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildDataField(
                      label: 'Runno Awal',
                      controller: _runnoAwalController,
                      isEditable: isCurrentlyEditable,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      customFillColor: Colors.white, // Pastikan putih
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDataField(
                      label: 'Runno Akhir',
                      controller: _runnoAkhirController,
                      isEditable: isCurrentlyEditable,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      customFillColor: Colors.white, // Pastikan putih
                    ),
                  ),
                ],
              ),
              // Tidak ada SizedBox di sini untuk menghilangkan space kosong di bawah
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool isQtyField = false,
    TextAlign textAlign = TextAlign.start,
    FloatingLabelAlignment floatingLabelAlignment =
        FloatingLabelAlignment.start,
    Color? customFillColor, // New parameter
    BorderSide? customBorderSide, // New parameter
  }) {
    // Determine if the field is read-only based on logic, or if it's the QTY field
    final bool isFieldReadOnly = !isEditable || isQtyField;

    return TextFormField(
      controller: controller,
      readOnly: isFieldReadOnly, // Use the determined read-only state
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style: TextStyle(
        // Warna teks lebih kontras: hitam jika editable, abu-abu jika read-only
        color: isFieldReadOnly ? Colors.grey[700] : Colors.black87,
        fontSize: 14,
      ),
      onChanged:
          isFieldReadOnly
              ? null
              : (value) => _onChanged(), // Pindahkan onChanged ke sini
      decoration: _buildInputDecoration(
        labelText: label,
        inputBorderSide: widget.darkBlueCardBorderSide,
        isFieldReadOnly: isFieldReadOnly, // Pass the determined read-only state
        textAlign: textAlign,
        floatingLabelAlignment: floatingLabelAlignment,
        customFillColor: customFillColor, // Pass custom fill color
        customBorderSide: customBorderSide, // Pass custom border side
      ),
    );
  }
}
