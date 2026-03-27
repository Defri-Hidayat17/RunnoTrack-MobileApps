import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Jika masih digunakan di AdminMainScaffold
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Untuk File
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Untuk loading indicator
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar

// Import untuk logout
import 'package:runnotrack/loginpage.dart';
// Import widget MemberCard yang baru dibuat
import 'package:runnotrack/widgets/member_card.dart'; // SESUAIKAN DENGAN PATH FILE ANDA

// Definisi base URL untuk API Anda
const String _baseUrl = 'http://192.168.1.10/runnotrack_api';

// --- Model untuk data Pimpinan ---
class Pimpinan {
  final int id;
  final String name;
  final String department; // Jabatan/Departemen
  final String phoneNumber;
  final String? photoUrl;
  final int? userId; // Tambahkan ini untuk ID user dari tabel users

  Pimpinan({
    required this.id,
    required this.name,
    required this.department,
    required this.phoneNumber,
    this.photoUrl,
    this.userId, // Tambahkan di konstruktor
  });

  factory Pimpinan.fromJson(Map<String, dynamic> json) {
    return Pimpinan(
      id: int.parse(json['id'].toString()),
      name: json['pimpinan_name'] ?? 'Unknown',
      department: json['department'] ?? 'N/A',
      phoneNumber: json['phone_number'] ?? 'N/A',
      photoUrl: json['photo_url'],
      userId:
          json['user_id'] != null
              ? int.parse(json['user_id'].toString())
              : null, // Parse user_id
    );
  }
}

// --- Model untuk data Operator (Checkers) ---
class Checker {
  final int id;
  final String name;
  final String groupCode;
  final String associatedAccountType;
  final String? phoneNumber;
  final String? photoUrl;
  final int? userId; // Tambahkan ini untuk ID user dari tabel users

  Checker({
    required this.id,
    required this.name,
    required this.groupCode,
    required this.associatedAccountType,
    this.phoneNumber,
    this.photoUrl,
    this.userId, // Tambahkan di konstruktor
  });

  factory Checker.fromJson(Map<String, dynamic> json) {
    return Checker(
      id: int.parse(json['id'].toString()),
      name: json['checker_name'] ?? 'Unknown',
      groupCode: json['group_code'] ?? 'N/A',
      associatedAccountType: json['associated_account_type'] ?? 'N/A',
      phoneNumber: json['phone_number'],
      photoUrl: json['photo_url'],
      userId:
          json['user_id'] != null
              ? int.parse(json['user_id'].toString())
              : null, // Parse user_id
    );
  }
}

class ProfilPageAdmin extends StatefulWidget {
  final String loggedInUserAccountType;
  final String? loggedInUserPhotoUrl;
  final String? loggedInUsername;
  final int loggedInUserId; // ID user Admin yang sedang login

  const ProfilPageAdmin({
    super.key,
    required this.loggedInUserAccountType,
    this.loggedInUserPhotoUrl,
    this.loggedInUsername,
    required this.loggedInUserId,
  });

  @override
  State<ProfilPageAdmin> createState() => _ProfilPageAdminState();
}

class _ProfilPageAdminState extends State<ProfilPageAdmin> {
  int _selectedTabIndex = 0; // 0: Profil, 1: Pengaturan
  String _selectedCategory = 'Pimpinan'; // 'Pimpinan' atau 'Operator'

  // Data untuk menampilkan daftar Pimpinan/Operator
  List<Pimpinan> _pimpinanList = [];
  List<Checker> _checkersList = [];
  bool _isLoadingData = true;
  String? _errorMessageData;

  // --- Variabel untuk Form Tambah/Edit Member ---
  final GlobalKey<FormState> _memberFormKey =
      GlobalKey<FormState>(); // Form untuk member
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupCodeController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _newMemberType; // 'Pimpinan' atau 'Operator'
  File? _imageFile; // Untuk gambar profil yang baru dipilih
  bool _isAddingOrEditingMember =
      false; // Status loading untuk proses tambah/edit
  bool _removePhotoFlag = false; // Flag untuk menghapus foto saat edit

  // Untuk form edit
  int?
  _editingItemId; // ID dari item yang sedang diedit (dari tabel checkers/pimpinan_details)
  String? _editingItemType; // 'Pimpinan' atau 'Operator'
  String? _currentPhotoUrlForEdit; // URL foto lama saat edit (dari database)

  // --- Variabel untuk Form Ganti Password Admin ---
  final GlobalKey<FormState> _adminPasswordFormKey =
      GlobalKey<FormState>(); // Form untuk ganti password admin
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _isChangingPassword = false; // Untuk admin ganti password sendiri

  // --- Variabel untuk Form Reset Password User Lain ---
  final GlobalKey<FormState> _resetPasswordFormKey =
      GlobalKey<FormState>(); // Form untuk reset password user lain
  final TextEditingController _resetNewPasswordController =
      TextEditingController();
  final TextEditingController _resetConfirmNewPasswordController =
      TextEditingController();
  bool _isResettingPassword = false; // Untuk admin reset password user lain

  @override
  void initState() {
    super.initState();
    _fetchMembersData(); // Mengambil data Pimpinan dan Checker
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupCodeController.dispose();
    _departmentController.dispose();
    _phoneNumberController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _resetNewPasswordController.dispose();
    _resetConfirmNewPasswordController.dispose();
    super.dispose();
  }

  // --- Logika Pengambilan Data Pimpinan dan Checker ---
  Future<void> _fetchMembersData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessageData = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/get_admin_data.php',
        ), // API ini mengembalikan keduanya
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success']) {
          List<Pimpinan> fetchedPimpinan =
              (decodedResponse['pimpinan'] as List)
                  .map((data) => Pimpinan.fromJson(data))
                  .toList();
          List<Checker> fetchedCheckers =
              (decodedResponse['checkers'] as List)
                  .map((data) => Checker.fromJson(data))
                  .toList();

          setState(() {
            _pimpinanList = fetchedPimpinan;
            _checkersList = fetchedCheckers;
          });
        } else {
          _errorMessageData =
              decodedResponse['message'] ?? 'Gagal mengambil data.';
        }
      } else {
        _errorMessageData = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessageData = 'Error koneksi: $e';
      print('Error fetching members data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // --- Helper UI Umum ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  // --- Aksi Admin: Tambah/Edit Member ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _removePhotoFlag =
            false; // Jika memilih gambar baru, batalkan flag hapus foto
      });
    }
  }

  void _clearMemberForm() {
    _nameController.clear();
    _groupCodeController.clear();
    _departmentController.clear();
    _phoneNumberController.clear();
    setState(() {
      _newMemberType = null;
      _imageFile = null;
      _editingItemId = null;
      _editingItemType = null;
      _currentPhotoUrlForEdit = null;
      _removePhotoFlag = false;
    });
  }

  Future<void> _submitMemberForm() async {
    if (!_memberFormKey.currentState!.validate()) {
      return;
    }
    if (_newMemberType == null && _editingItemId == null) {
      _showSnackBar('Pilih tipe member (Pimpinan/Operator).');
      return;
    }

    setState(() {
      _isAddingOrEditingMember = true;
    });

    final uri = Uri.parse('$_baseUrl/admin_dashboard.php');
    final request = http.MultipartRequest('POST', uri);

    final String actualMemberType =
        _editingItemId != null ? _editingItemType! : _newMemberType!;

    if (_editingItemId != null) {
      // Mode Edit
      request.fields['form_type'] =
          actualMemberType == 'Pimpinan' ? 'edit_pimpinan' : 'edit_checker';
      request.fields['id'] = _editingItemId.toString();

      if (_currentPhotoUrlForEdit != null &&
          _currentPhotoUrlForEdit!.isNotEmpty) {
        // Hanya kirim nama file, bukan URL lengkap
        request.fields['current_photo_filename'] =
            Uri.parse(_currentPhotoUrlForEdit!).pathSegments.last;
      }
      if (_removePhotoFlag) {
        request.fields['remove_photo'] = '1';
      }
    } else {
      // Mode Add
      request.fields['form_type'] =
          actualMemberType == 'Pimpinan' ? 'add_pimpinan' : 'add_checker';
    }

    request.fields['name'] = _nameController.text;
    request.fields['phone_number'] = _phoneNumberController.text;

    if (actualMemberType == 'Pimpinan') {
      request.fields['department'] = _departmentController.text;
    } else {
      // Operator
      request.fields['group_code'] = _groupCodeController.text;
      request.fields['associated_account_type'] =
          'Checker'; // Selalu 'Checker' untuk operator
    }

    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo', // Nama field sesuai PHP
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
        _showSnackBar(decodedResponse['message'] ?? 'Operasi berhasil!');
        _clearMemberForm();
        if (mounted) {
          Navigator.of(context).pop(); // Tutup dialog setelah berhasil
          _fetchMembersData(); // Refresh data
        }
      } else {
        _showSnackBar(
          'Gagal melakukan operasi: ${decodedResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Error submitting member form: $e');
    } finally {
      setState(() {
        _isAddingOrEditingMember = false;
      });
    }
  }

  Future<void> _confirmDeleteMember(int id, String type, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Anda yakin ingin menghapus $name ($type)?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteMember(id, type);
    }
  }

  Future<void> _deleteMember(int id, String type) async {
    setState(() {
      _isLoadingData = true; // Tampilkan loading saat menghapus
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin_dashboard.php'),
        body: {
          'form_type':
              type == 'Pimpinan' ? 'delete_pimpinan' : 'delete_checker',
          'id': id.toString(),
        },
      );

      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 200 && decodedResponse['success']) {
        _showSnackBar(decodedResponse['message'] ?? 'Member berhasil dihapus!');
        _fetchMembersData(); // Refresh data setelah penghapusan
      } else {
        _showSnackBar(
          'Gagal menghapus member: ${decodedResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Error deleting member: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _showMemberFormDialog({
    int? id, // ID dari checkers/pimpinan_details
    String? type, // 'Pimpinan' atau 'Operator'
    String? name,
    String? phoneNumber,
    String? groupCode,
    String? department,
    String? photoUrl,
  }) {
    _clearMemberForm(); // Bersihkan form setiap kali dialog dibuka
    setState(() {
      _editingItemId = id;
      _editingItemType = type;
      _currentPhotoUrlForEdit = photoUrl;

      if (id != null) {
        // Mode Edit
        _newMemberType = type;
        _nameController.text = name ?? '';
        _phoneNumberController.text = phoneNumber ?? '';
        if (type == 'Pimpinan') {
          _departmentController.text = department ?? '';
        } else {
          // Operator
          _groupCodeController.text = groupCode ?? '';
        }
        _removePhotoFlag = false; // Reset flag saat membuka dialog edit
      } else {
        // Mode Add
        _newMemberType = 'Operator'; // Default ke Operator
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(id != null ? 'Edit Member' : 'Tambah Member Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: _memberFormKey, // Gunakan _memberFormKey di sini
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          setStateDialog(() {
                            _removePhotoFlag =
                                false; // Jika memilih gambar baru, batalkan flag hapus foto
                          });
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (photoUrl != null &&
                                          photoUrl!
                                              .isNotEmpty && // Perbaikan di sini
                                          !_removePhotoFlag
                                      ? NetworkImage(photoUrl)
                                      : null),
                          child:
                              (_imageFile == null &&
                                      (photoUrl == null ||
                                          photoUrl!
                                              .isEmpty || // Perbaikan di sini
                                          _removePhotoFlag))
                                  ? Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  )
                                  : null,
                        ),
                      ),
                      if (id != null &&
                          photoUrl != null &&
                          photoUrl!
                              .isNotEmpty) // Tampilkan opsi hapus foto hanya jika edit dan ada foto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _removePhotoFlag,
                              onChanged: (bool? value) {
                                setStateDialog(() {
                                  _removePhotoFlag = value ?? false;
                                  if (_removePhotoFlag) {
                                    _imageFile =
                                        null; // Jika menghapus, bersihkan pilihan gambar baru
                                  }
                                });
                              },
                            ),
                            const Text('Hapus Foto Ini'),
                          ],
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value:
                            _newMemberType ??
                            'Operator', // Default value for add mode
                        decoration: const InputDecoration(
                          labelText: 'Tipe Member',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Pilih Tipe Member'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pimpinan',
                            child: Text('Pimpinan'),
                          ),
                          DropdownMenuItem(
                            value: 'Operator',
                            child: Text('Operator'),
                          ),
                        ],
                        onChanged:
                            _editingItemId != null
                                ? null // Disable dropdown if editing
                                : (String? newValue) {
                                  setStateDialog(() {
                                    _newMemberType = newValue;
                                  });
                                },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tipe member tidak boleh kosong';
                          }
                          return null;
                        },
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
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_newMemberType == 'Operator' ||
                          (_editingItemId != null &&
                              _editingItemType == 'Operator'))
                        TextFormField(
                          controller: _groupCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Kode Grup (Operator)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((_newMemberType == 'Operator' ||
                                    (_editingItemId != null &&
                                        _editingItemType == 'Operator')) &&
                                (value == null || value.isEmpty)) {
                              return 'Kode Grup tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      if (_newMemberType == 'Pimpinan' ||
                          (_editingItemId != null &&
                              _editingItemType == 'Pimpinan'))
                        TextFormField(
                          controller: _departmentController,
                          decoration: const InputDecoration(
                            labelText:
                                'Jabatan/Departemen (Pimpinan)', // Label untuk jabatan Pimpinan
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((_newMemberType == 'Pimpinan' ||
                                    (_editingItemId != null &&
                                        _editingItemType == 'Pimpinan')) &&
                                (value == null || value.isEmpty)) {
                              return 'Jabatan/Departemen tidak boleh kosong';
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
                    if (!_isAddingOrEditingMember) {
                      Navigator.of(dialogContext).pop();
                      _clearMemberForm();
                    }
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color:
                          _isAddingOrEditingMember ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isAddingOrEditingMember ? null : _submitMemberForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03112B),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isAddingOrEditingMember
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(id != null ? 'Update' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Logika Ganti Password Admin (untuk admin yang login) ---
  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    bool _obscureOldPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmNewPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Ganti Password Admin'),
              content: SingleChildScrollView(
                child: Form(
                  key: _adminPasswordFormKey, // Gunakan _adminPasswordFormKey
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOldPassword,
                        decoration: InputDecoration(
                          labelText: 'Password Lama',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOldPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _obscureOldPassword = !_obscureOldPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password lama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmNewPasswordController,
                        obscureText: _obscureConfirmNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _obscureConfirmNewPassword =
                                    !_obscureConfirmNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Password baru dan konfirmasi tidak cocok';
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
                    if (!_isChangingPassword) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: _isChangingPassword ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isChangingPassword
                          ? null
                          : () => _submitChangePassword(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03112B),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isChangingPassword
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Ganti Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitChangePassword(BuildContext dialogContext) async {
    if (!_adminPasswordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin_dashboard.php'),
        body: {
          'form_type': 'change_password',
          'user_id':
              widget.loggedInUserId
                  .toString(), // Menggunakan ID user Admin yang sedang login
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        },
      );

      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 200 && decodedResponse['success']) {
        _showSnackBar(
          decodedResponse['message'] ?? 'Password berhasil diubah!',
        );
        if (mounted) {
          Navigator.of(dialogContext).pop(); // Tutup dialog setelah berhasil
        }
      } else {
        _showSnackBar(
          'Gagal mengubah password: ${decodedResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Error changing admin password: $e');
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  // --- Logika Reset Password User Lain (oleh Admin) ---
  void _showResetPasswordDialog(
    int userId, // Ini sekarang non-nullable karena dipanggil dengan userId!
    String userName,
    String userAccountType,
  ) {
    _resetNewPasswordController.clear();
    _resetConfirmNewPasswordController.clear();
    bool _obscureNewPassword = true;
    bool _obscureConfirmNewPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Reset Password untuk $userName ($userAccountType)'),
              content: SingleChildScrollView(
                child: Form(
                  key: _resetPasswordFormKey, // Gunakan _resetPasswordFormKey
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _resetNewPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _resetConfirmNewPasswordController,
                        obscureText: _obscureConfirmNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                _obscureConfirmNewPassword =
                                    !_obscureConfirmNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _resetNewPasswordController.text) {
                            return 'Password baru dan konfirmasi tidak cocok';
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
                    if (!_isResettingPassword) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: _isResettingPassword ? Colors.grey : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isResettingPassword
                          ? null
                          : () => _submitResetPassword(dialogContext, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03112B),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isResettingPassword
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitResetPassword(
    BuildContext dialogContext,
    int userId,
  ) async {
    if (!_resetPasswordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin_dashboard.php'),
        body: {
          'form_type': 'admin_reset_password', // Form type baru
          'user_id': userId.toString(),
          'new_password': _resetNewPasswordController.text,
        },
      );

      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 200 && decodedResponse['success']) {
        _showSnackBar(
          decodedResponse['message'] ?? 'Password user berhasil direset!',
        );
        if (mounted) {
          Navigator.of(dialogContext).pop(); // Tutup dialog setelah berhasil
        }
      } else {
        _showSnackBar(
          'Gagal mereset password user: ${decodedResponse['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      print('Error resetting user password: $e');
    } finally {
      setState(() {
        _isResettingPassword = false;
      });
    }
  }

  // --- Logika Logout ---
  Future<void> _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Zona Berbahaya ⚠️",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const Text("Apakah kamu yakin ingin logout dari akun ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Logout"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Page harus warna putih
      body: Stack(
        children: [
          Column(
            children: [
              // --- Bagian Header Profil Admin (FIXED) ---
              Container(
                padding: const EdgeInsets.only(
                  top: 5, // Jarak foto user ke app bar lebih dekat
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          widget.loggedInUserPhotoUrl != null &&
                                  widget.loggedInUserPhotoUrl!.isNotEmpty
                              ? NetworkImage(widget.loggedInUserPhotoUrl!)
                              : null,
                      child:
                          widget.loggedInUserPhotoUrl == null ||
                                  widget.loggedInUserPhotoUrl!.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.loggedInUsername ??
                          'Admin', // Hanya menampilkan username
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // --- Navigation Tabs (FIXED) ---
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2547),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(0, Icons.group, 'Manajemen Member'),
                    _buildTabItem(1, Icons.settings, 'Pengaturan'),
                  ],
                ),
              ),
              // --- Konten berdasarkan tab yang dipilih (SCROLLABLE) ---
              Expanded(
                child:
                    _buildTabContent(), // _buildTabContent sekarang akan mengelola scroll dengan benar
              ),
            ],
          ),
          // --- Floating Action Button untuk Tambah Member ---
          Positioned(
            bottom: 20, // POSISI DIUBAH AGAR TIDAK TERTUTUP BOTTOM NAV
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => _showMemberFormDialog(),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Tambah Member Baru',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF03112B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // --- Loading Overlay untuk Dialog ---
          if (_isAddingOrEditingMember ||
              _isChangingPassword ||
              _isResettingPassword)
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
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF03112B) : Colors.white,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF03112B) : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMemberManagementContent();
      case 1:
        return _buildPengaturanContent();
      default:
        return Container();
    }
  }

  Widget _buildMemberManagementContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDBE6F2), // Warna box manajemen member
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                255,
                255,
                255,
              ), // Warna box toggle Pimpinan/Operator
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildCategoryToggleButton('Pimpinan'),
                _buildCategoryToggleButton('Operator'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // List member yang bisa di-scroll
          Expanded(
            child:
                _isLoadingData
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                    : _errorMessageData != null
                    ? Center(
                      child: Text(
                        'Error: $_errorMessageData',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : _buildMemberList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggleButton(String category) {
    bool isSelected = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF0D2547)
                    : const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    List<dynamic> currentList =
        _selectedCategory == 'Pimpinan' ? _pimpinanList : _checkersList;
    if (currentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Tidak ada data ${_selectedCategory} untuk ditampilkan.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final item = currentList[index];
        String name;
        String description;
        String? photoUrl;
        String itemType;
        int id;
        String? phoneNumber;
        String? groupCode;
        String? department;
        int? userId;

        if (item is Pimpinan) {
          id = item.id;
          name = item.name;
          description = item.department;
          photoUrl = item.photoUrl;
          itemType = 'Pimpinan';
          phoneNumber = item.phoneNumber;
          department = item.department;
          userId = item.userId;
        } else if (item is Checker) {
          id = item.id;
          name = item.name;
          description =
              item.groupCode.isNotEmpty
                  ? item.groupCode
                  : item.associatedAccountType;
          photoUrl = item.photoUrl;
          itemType = 'Operator';
          phoneNumber = item.phoneNumber;
          groupCode = item.groupCode;
          userId = item.userId;
        } else {
          return const SizedBox.shrink();
        }

        return MemberCard(
          id: id,
          name: name,
          description: description,
          photoUrl: photoUrl,
          itemType: itemType,
          phoneNumber: phoneNumber,
          groupCode: groupCode,
          department: department,
          userId: userId,
          onEdit: () {
            _showMemberFormDialog(
              id: id,
              type: itemType,
              name: name,
              phoneNumber: phoneNumber,
              groupCode: groupCode,
              department: department,
              photoUrl: photoUrl,
            );
          },
          onDelete: () {
            _confirmDeleteMember(id, itemType, name);
          },
          onResetPassword:
              userId != null
                  ? () {
                    // Perbaikan di sini: userId!
                    _showResetPasswordDialog(userId!, name, itemType);
                  }
                  : null,
        );
      },
    );
  }

  Widget _buildPengaturanContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDBE6F2), // Warna box pengaturan
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text(
              'Ganti Password Admin', // Ubah teks agar lebih jelas
              style: TextStyle(color: Color(0xFF0D2547)),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF0D2547),
            ),
            onTap:
                _showChangePasswordDialog, // Panggil dialog ganti password admin
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _logout, // Logout dengan konfirmasi
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
