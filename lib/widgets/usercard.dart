import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Tetap butuh ini untuk SvgPicture

class UserCard extends StatelessWidget {
  final String name;
  final String
  accountType; // Untuk Pimpinan: Department, Untuk Checker: Associated Account Type
  final String? groupCode; // Hanya untuk Checker, bisa null
  final String phoneNumber;
  final String? photoUrl;
  final VoidCallback? onTapImage;
  final VoidCallback? onTapWhatsApp; // Callback untuk membuka WhatsApp

  const UserCard({
    super.key,
    required this.name,
    required this.accountType,
    this.groupCode,
    required this.phoneNumber,
    this.photoUrl,
    this.onTapImage,
    this.onTapWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3, // Sedikit lebih tinggi untuk kesan modern
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding yang konsisten
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar Profil
            GestureDetector(
              onTap: onTapImage,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: ClipOval(
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
                          : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Detail Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Sedikit lebih besar untuk nama
                      color: Color(0xFF03112B),
                    ),
                  ),
                  const SizedBox(height: 6), // Spasi antar elemen
                  Text(
                    accountType,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14, // Sedikit lebih besar
                    ),
                  ),
                  if (groupCode != null && groupCode!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4.0,
                      ), // Sedikit spasi di atas grup
                      child: Text(
                        'Grup: $groupCode',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  // --- SEKAT/DIVIDER UNTUK STRUKTUR ---
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                    ), // Padding vertikal untuk sekat
                    child: Divider(
                      height: 1, // Tinggi sekat
                      thickness: 1, // Ketebalan sekat
                      color: Colors.grey, // Warna sekat
                      indent: 0, // Indentasi dari kiri
                      endIndent: 0, // Indentasi dari kanan
                    ),
                  ),

                  // --- AKHIR SEKAT ---
                  GestureDetector(
                    onTap: onTapWhatsApp,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/wa.svg', // Path SVG yang diperbarui
                          height: 20, // Ukuran ikon sedikit lebih besar
                          width: 20,
                          // colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn), // <<< DIHAPUS
                        ),
                        const SizedBox(width: 8), // Spasi lebih besar
                        Text(
                          phoneNumber,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 15, // Ukuran font sedikit lebih besar
                            fontWeight: FontWeight.w600, // Lebih tebal
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
