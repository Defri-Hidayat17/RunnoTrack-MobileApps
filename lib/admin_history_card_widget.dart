// lib/admin_history_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runnotrack/models/history_entry.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminHistoryCardWidget extends StatelessWidget {
  final HistoryEntry entry;
  final String userName; // Diterima secara eksplisit
  final String userPhotoUrl; // Diterima secara eksplisit
  final String userAccountType; // Diterima secara eksplisit
  final VoidCallback? onTap;
  final VoidCallback? onScreenshotTap;

  const AdminHistoryCardWidget({
    super.key,
    required this.entry,
    required this.userName,
    required this.userPhotoUrl,
    required this.userAccountType,
    this.onTap,
    this.onScreenshotTap,
  });

  static const Color _darkBlueStrokeColor = Color(0xFF03112B);

  Widget _buildSummaryFloatingLabelBox({
    required String label,
    required String value,
    Color valueColor = Colors.black87,
    FontWeight fontWeight = FontWeight.normal,
    IconData? icon,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _darkBlueStrokeColor.withOpacity(0.8),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = entry.entryDate;

    Color differenceColor = Colors.blue;
    IconData? differenceIcon;
    if (entry.difference < 0) {
      differenceColor = Colors.red;
      differenceIcon = Icons.arrow_downward;
    } else if (entry.difference > 0) {
      differenceColor = Colors.green;
      differenceIcon = Icons.arrow_upward;
    }

    String differenceText =
        entry.difference > 0
            ? '+${entry.difference}'
            : entry.difference.toString();

    final clampedEfficiency = entry.efficiencyPercentage.clamp(0.0, 100.0);

    Color efficiencyBarColor;
    if (entry.efficiencyPercentage < 70) {
      efficiencyBarColor = Colors.red;
    } else if (entry.efficiencyPercentage >= 70 &&
        entry.efficiencyPercentage < 85) {
      efficiencyBarColor = Colors.orange;
    } else {
      efficiencyBarColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, 3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Informasi Pengguna (Nama, Foto, Tipe Akun)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          userPhotoUrl.isNotEmpty
                              ? NetworkImage(userPhotoUrl)
                              : null,
                      child:
                          userPhotoUrl.isEmpty
                              ? Icon(
                                Icons.person,
                                size: 15,
                                color: Colors.grey.shade600,
                              )
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF03112B),
                          ),
                        ),
                        Text(
                          '($userAccountType)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status Konfirmasi
                Text(
                  entry.isConfirmed ? 'Confirmed' : 'Pending',
                  style: TextStyle(
                    color: entry.isConfirmed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1), // Pemisah
            // Informasi Riwayat Utama
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal: $formattedDate',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF03112B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grup: ${entry.groupCode}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Checker: ${entry.checkerUsername}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (onScreenshotTap != null)
                  GestureDetector(
                    onTap: onScreenshotTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _darkBlueStrokeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/ss.svg',
                          height: 16,
                          width: 16,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              children: [
                _buildSummaryFloatingLabelBox(
                  label: 'Target',
                  value: entry.totalTarget.toString(),
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 4),
                _buildSummaryFloatingLabelBox(
                  label: 'Actual',
                  value: entry.totalActualQty.toString(),
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 4),
                _buildSummaryFloatingLabelBox(
                  label: 'Diff',
                  value: differenceText,
                  valueColor: differenceColor,
                  fontWeight: FontWeight.bold,
                  icon: differenceIcon,
                  iconColor: differenceColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress Efficiency:',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      '${entry.efficiencyPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: efficiencyBarColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: clampedEfficiency / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      efficiencyBarColor,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
