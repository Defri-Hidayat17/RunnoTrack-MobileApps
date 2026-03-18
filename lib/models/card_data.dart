// lib/models/card_data.dart

/// Model Data untuk menyimpan informasi satu kartu input.
class CardData {
  final int id;
  final String model;
  final String runnoAwal;
  final String runnoAkhir;
  final String qty;
  final bool hasChanges; // Menunjukkan apakah ada perubahan yang belum disimpan

  CardData({
    required this.id,
    this.model = '',
    this.runnoAwal = '',
    this.runnoAkhir = '',
    this.qty = '',
    this.hasChanges = false,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id'] as int,
      model: json['model'] as String,
      runnoAwal: json['runnoAwal'] as String,
      runnoAkhir: json['runnoAkhir'] as String,
      qty: json['qty'] as String,
      hasChanges:
          (json['hasChanges'] as bool?) ?? false, // Handle null for older data
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'runnoAwal': runnoAwal,
      'runnoAkhir': runnoAkhir,
      'qty': qty,
      'hasChanges': hasChanges,
    };
  }

  CardData copyWith({
    String? model,
    String? runnoAwal,
    String? runnoAkhir,
    String? qty,
    bool? hasChanges,
  }) {
    return CardData(
      id: id,
      model: model ?? this.model,
      runnoAwal: runnoAwal ?? this.runnoAwal,
      runnoAkhir: runnoAkhir ?? this.runnoAkhir,
      qty: qty ?? this.qty,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}
