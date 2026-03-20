import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runnotrack/loginpage.dart'; // Untuk logout
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar
import 'dart:io'; // Untuk File
import 'package:http/http.dart' as http; // Untuk request HTTP
import 'dart:convert'; // Untuk json.decode
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Untuk loading indicator

const String _baseUrl =
    'http://192.168.1.10/runnotrack_api'; // Pastikan IP ini benar

class ProfilPageAdmin extends StatefulWidget {
  final String userName;
  final String userRole;
  final String userAccountType;
  final String userPhotoUrl;

  const ProfilPageAdmin({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userAccountType,
    required this.userPhotoUrl,
  });

  @override
  State<ProfilPageAdmin> createState() => _ProfilPageAdminState();
}

class _ProfilPageAdminState extends State<ProfilPageAdmin> {
  // --- Variabel untuk Form Tambah Member ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedRole; // Untuk dropdown jabatan
  File? _imageFile; // Untuk gambar profil
  bool _isAddingMember = false; // Status loading untuk proses tambah member
  bool _obscurePassword = true;

  final List<String> _roles = [
    'Pimpinan',
    'Member',
    'Supervisor',
  ]; // Contoh jabatan

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data SharedPreferences
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false, // Hapus semua route sebelumnya
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRole == null) {
      _showSnackBar('Pilih jabatan untuk member baru.');
      return;
    }

    setState(() {
      _isAddingMember = true;
    });

    final uri = Uri.parse('$_baseUrl/add_member.php');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['name'] = _nameController.text
          ..fields['username'] = _usernameController.text
          ..fields['password'] = _passwordController.text
          ..fields['role'] = _selectedRole!
          ..fields['account_type'] =
              'User'; // Default untuk member baru adalah 'User'

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_photo',
          _imageFile!.path,
          filename: _imageFile!.path.split('/').last,
        ),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseBody);

      if (response.statusCode == 200 && decodedResponse['success']) {
        _showSnackBar('Member baru berhasil ditambahkan!');
        _clearForm();
        if (mounted) {
          Navigator.of(context).pop(); // Tutup dialog setelah berhasil
        }
      } else {
        _showSnackBar(
          'Gagal menambahkan member: ${decodedResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Error adding member: $e');
    } finally {
      setState(() {
        _isAddingMember = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRole = null;
      _imageFile = null;
      _obscurePassword = true; // Reset obscure text
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showAddMemberDialog() {
    _clearForm(); // Bersihkan form setiap kali dialog dibuka
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Menggunakan StatefulBuilder untuk me-rebuild dialog
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Tambah Member Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          setState(() {}); // Rebuild dialog untuk update gambar
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : null,
                          child:
                              _imageFile == null
                                  ? Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                // Rebuild dialog untuk update ikon
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Jabatan',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Pilih Jabatan'),
                        items:
                            _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            // Rebuild dialog untuk update nilai dropdown
                            _selectedRole = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jabatan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!_isAddingMember) {
                      // Hanya bisa ditutup jika tidak sedang loading
                      Navigator.of(dialogContext).pop();
                      _clearForm(); // Pastikan form bersih saat dialog ditutup
                    }
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: _isAddingMember ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isAddingMember ? null : _addMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03112B),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isAddingMember
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Menggunakan Stack untuk overlay loading
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      widget.userPhotoUrl.isNotEmpty
                          ? NetworkImage(widget.userPhotoUrl)
                          : null,
                  child:
                      widget.userPhotoUrl.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${widget.userRole}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Tipe Akun: ${widget.userAccountType}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _showAddMemberDialog, // Panggil dialog
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Tambah Member Baru',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03112B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlay loading untuk dialog tambah member
        if (_isAddingMember)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: LoadingAnimationWidget.twistingDots(
                  leftDotColor: const Color(0xFF062B59),
                  rightDotColor: const Color.fromARGB(255, 255, 255, 255),
                  size: 80,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
