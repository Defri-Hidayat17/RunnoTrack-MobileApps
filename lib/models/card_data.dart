// lib/models/card_data.dart

import 'package:flutter/foundation.dart'; // Import untuk @immutable

@immutable // Menandakan bahwa objek ini tidak dapat diubah setelah dibuat
class CardData {
  final int
  id; // ID unik untuk kartu di UI (lokal, untuk identifikasi dalam list)
  final int?
  cardDetailId; // ID unik untuk detail kartu di database (bisa null jika kartu baru)
  final String model;
  final String runnoAwal;
  final String runnoAkhir;
  final String qty;
  final bool hasChanges; // Menunjukkan apakah ada perubahan yang belum disimpan
  final bool
  shouldResetEditMode; // Sinyal untuk mereset mode edit di widget kartu

  const CardData({
    required this.id,
    this.cardDetailId,
    this.model = '',
    this.runnoAwal = '',
    this.runnoAkhir = '',
    this.qty = '',
    this.hasChanges = false,
    this.shouldResetEditMode = false,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    // ID dari database (tracking_card_details.id) akan ada di kunci 'id' dari JSON
    final int dbId =
        int.tryParse(json['id'].toString()) ?? 0; // Pastikan parsing ke int

    return CardData(
      id: dbId, // Gunakan ID dari DB sebagai ID lokal untuk konsistensi di riwayat
      cardDetailId: dbId, // Ini adalah ID sebenarnya dari database
      model: json['model'] as String? ?? '', // Tambahkan null safety
      runnoAwal: json['runno_awal'] as String? ?? '', // Tambahkan null safety
      runnoAkhir: json['runno_akhir'] as String? ?? '', // Tambahkan null safety
      qty:
          json['qty']?.toString() ??
          '0', // Pastikan qty selalu string, tambahkan null safety
      hasChanges: false, // Saat dimuat dari DB, tidak ada perubahan
      shouldResetEditMode:
          false, // Selalu default ke false saat memuat dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    // Saat mengirim ke backend (misalnya untuk update/delete di Hasilpage),
    // kita harus mengirim cardDetailId sebagai 'id' yang diharapkan oleh backend.
    return {
      'id': cardDetailId, // Ini adalah ID database yang sebenarnya
      'model': model,
      'runno_awal': runnoAwal,
      'runno_akhir': runnoAkhir,
      'qty': int.tryParse(qty) ?? 0, // Pastikan qty dikirim sebagai integer
      // hasChanges dan shouldResetEditMode adalah status UI, tidak untuk persistensi backend.
    };
  }

  CardData copyWith({
    int? id,
    int? cardDetailId,
    String? model,
    String? runnoAwal,
    String? runnoAkhir,
    String? qty,
    bool? hasChanges,
    bool? shouldResetEditMode,
  }) {
    return CardData(
      id: id ?? this.id,
      cardDetailId: cardDetailId ?? this.cardDetailId,
      model: model ?? this.model,
      runnoAwal: runnoAwal ?? this.runnoAwal,
      runnoAkhir: runnoAkhir ?? this.runnoAkhir,
      qty: qty ?? this.qty,
      hasChanges: hasChanges ?? this.hasChanges,
      shouldResetEditMode: shouldResetEditMode ?? this.shouldResetEditMode,
    );
  }

  // Menambahkan operator == dan hashCode untuk perbandingan yang efisien
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardData &&
        other.id == id &&
        other.cardDetailId == cardDetailId &&
        other.model == model &&
        other.runnoAwal == runnoAwal &&
        other.runnoAkhir == runnoAkhir &&
        other.qty == qty &&
        other.hasChanges == hasChanges &&
        other.shouldResetEditMode == shouldResetEditMode;
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardDetailId,
    model,
    runnoAwal,
    runnoAkhir,
    qty,
    hasChanges,
    shouldResetEditMode,
  );

  // Tambahkan toString untuk debugging yang lebih baik
  @override
  String toString() {
    return 'CardData(id: $id, cardDetailId: $cardDetailId, model: $model, runnoAwal: $runnoAwal, runnoAkhir: $runnoAkhir, qty: $qty, hasChanges: $hasChanges, shouldResetEditMode: $shouldResetEditMode)';
  }
}
