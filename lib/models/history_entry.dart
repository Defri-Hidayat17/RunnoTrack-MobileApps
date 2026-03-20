// lib/models/history_entry.dart
import 'package:intl/intl.dart';

class HistoryEntry {
  final int id;
  final String entryDate;
  final String groupCode;
  final String checkerUsername;
  final int totalTarget;
  final bool isConfirmed;
  final int totalActualQty;
  final int difference;
  final double efficiencyPercentage;
  final String? createdAt;
  final String productionType;
  final String userAccountType; // ✅ Tambahkan ini
  final String userName; // ✅ Tambahkan ini
  final String userPhotoUrl; // ✅ Tambahkan ini

  HistoryEntry({
    required this.id,
    required this.entryDate,
    required this.groupCode,
    required this.checkerUsername,
    required this.totalTarget,
    required this.isConfirmed,
    required this.totalActualQty,
    required this.difference,
    required this.efficiencyPercentage,
    this.createdAt,
    required this.productionType,
    required this.userAccountType, // ✅ Tambahkan ini
    required this.userName, // ✅ Tambahkan ini
    required this.userPhotoUrl, // ✅ Tambahkan ini
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    String formattedDate = DateFormat(
      'dd/MM/yy',
    ).format(DateFormat('yyyy-MM-dd').parse(json['entry_date']));

    return HistoryEntry(
      id: int.parse(json['id'].toString()),
      entryDate: formattedDate,
      groupCode: json['group_code'] ?? 'N/A',
      checkerUsername: json['checker_username'] ?? 'N/A',
      totalTarget: int.tryParse(json['total_target'].toString()) ?? 0,
      isConfirmed:
          json['is_confirmed'] as bool? ??
          false, // Menginterpretasikan langsung sebagai boolean
      totalActualQty: int.tryParse(json['total_actual_qty'].toString()) ?? 0,
      difference: int.tryParse(json['difference'].toString()) ?? 0,
      efficiencyPercentage:
          double.tryParse(json['efficiency_percentage'].toString()) ?? 0.0,
      createdAt: json['created_at'] as String?,
      productionType: json['production_type'] as String? ?? 'N/A',
      userAccountType:
          json['user_account_type'] as String? ?? 'N/A', // ✅ Parse ini
      userName: json['user_name'] as String? ?? 'N/A', // ✅ Parse ini
      userPhotoUrl: json['user_photo_url'] as String? ?? '', // ✅ Parse ini
    );
  }

  HistoryEntry copyWith({
    int? id,
    String? entryDate,
    String? groupCode,
    String? checkerUsername,
    int? totalTarget,
    bool? isConfirmed,
    int? totalActualQty,
    int? difference,
    double? efficiencyPercentage,
    String? createdAt,
    String? productionType,
    String? userAccountType, // ✅ Tambahkan ini
    String? userName, // ✅ Tambahkan ini
    String? userPhotoUrl, // ✅ Tambahkan ini
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      groupCode: groupCode ?? this.groupCode,
      checkerUsername: checkerUsername ?? this.checkerUsername,
      totalTarget: totalTarget ?? this.totalTarget,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      totalActualQty: totalActualQty ?? this.totalActualQty,
      difference: difference ?? this.difference,
      efficiencyPercentage: efficiencyPercentage ?? this.efficiencyPercentage,
      createdAt: createdAt ?? this.createdAt,
      productionType: productionType ?? this.productionType,
      userAccountType:
          userAccountType ?? this.userAccountType, // ✅ Tambahkan ini
      userName: userName ?? this.userName, // ✅ Tambahkan ini
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl, // ✅ Tambahkan ini
    );
  }
}
