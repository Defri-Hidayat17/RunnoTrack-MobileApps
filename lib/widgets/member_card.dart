import 'package:flutter/material.dart';

class MemberCard extends StatelessWidget {
  final int id;
  final String name;
  final String description;
  final String? photoUrl;
  final String itemType; // 'Pimpinan' atau 'Operator'
  final String? phoneNumber;
  final String? groupCode;
  final String? department;
  final int? userId; // Untuk reset password functionality

  // Callbacks untuk aksi-aksi yang mungkin dilakukan admin
  // Dibuat nullable agar widget ini bisa digunakan di konteks non-admin juga
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onResetPassword;

  const MemberCard({
    Key? key,
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.itemType,
    this.phoneNumber,
    this.groupCode,
    this.department,
    this.userId,
    this.onEdit,
    this.onDelete,
    this.onResetPassword,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // Warna box setiap member
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Efek 3D
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: ClipOval(
              // Perbaikan di sini: photoUrl != null && photoUrl!.isNotEmpty
              child:
                  photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            ),
                      )
                      : const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          // Tombol Reset Password (hanya jika ada userId terkait dan callback diberikan)
          if (userId != null && onResetPassword != null)
            IconButton(
              icon: const Icon(Icons.vpn_key, color: Colors.blueGrey),
              onPressed: onResetPassword,
            ),
          // Tombol Edit (hanya jika callback diberikan)
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF03112B)),
              onPressed: onEdit,
            ),
          // Tombol Delete (hanya jika callback diberikan)
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
