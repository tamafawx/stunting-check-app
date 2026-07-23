// Halaman untuk mengedit data balita dari data yang ada.

// Role yang dapat akses:
// - Kader

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';

import 'balita_cari_orangtua.dart';

class EditBalitaScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditBalitaScreen({super.key, required this.docId, required this.data});

  @override
  State<EditBalitaScreen> createState() => _EditBalitaScreenState();
}

class _EditBalitaScreenState extends State<EditBalitaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  String? _jenisKelamin;
  DateTime? _tanggalLahir;
  bool _isLoading = false;

  // Foto State
  File? _imageFile;
  String? _currentImageUrl;
  bool _isImageDeleted = false;
  final ImagePicker _picker = ImagePicker();

  // Multi Orang Tua State
  List<Map<String, String>> _selectedParents = [];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.data['nama']);
    _jenisKelamin = widget.data['jenisKelamin'];

    // Parse Tanggal Lahir
    if (widget.data['tanggalLahir'] != null) {
      _tanggalLahir = (widget.data['tanggalLahir'] as Timestamp).toDate();
    }

    _currentImageUrl = widget.data['fotoUrl'];

    // Load Orang Tua jika sudah format array
    if (widget.data['orangTuaIds'] != null &&
        widget.data['orangTuaNames'] != null) {
      List<dynamic> ids = widget.data['orangTuaIds'];
      List<dynamic> names = widget.data['orangTuaNames'];

      for (int i = 0; i < ids.length; i++) {
        if (i < names.length) {
          _selectedParents.add({
            'id': ids[i].toString(),
            'name': names[i].toString(),
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _cropImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cropImage(String path) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto Balita',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(title: 'Sesuaikan Foto', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
          _isImageDeleted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyesuaikan gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  'Atur Foto Balita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_imageFile != null ||
                        (_currentImageUrl != null && !_isImageDeleted))
                      _buildOptionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Hapus',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _imageFile = null;
                            _isImageDeleted = true;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      String fileName = 'balita_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('balita_profiles')
          .child(fileName);
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _bukaPencarianOrangTua() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CariOrangTuaScreen(initialSelection: _selectedParents),
      ),
    );
    if (result != null && result is List<Map<String, String>>) {
      setState(() {
        _selectedParents = result;
      });
    }
  }

  Future<void> _updateData() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggalLahir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal lahir wajib diisi'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      if (_selectedParents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih minimal satu Orang Tua/Wali'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String? finalFotoUrl = _currentImageUrl;
        if (_isImageDeleted) {
          finalFotoUrl = null;
        } else if (_imageFile != null) {
          finalFotoUrl = await _uploadImage();
        }

        List<String> ortuIds = _selectedParents.map((e) => e['id']!).toList();
        List<String> ortuNames = _selectedParents
            .map((e) => e['name']!)
            .toList();
        String joinedNames = ortuNames.join(', ');

        Map<String, dynamic> updateData = {
          'nama': _namaController.text.trim(),
          'jenisKelamin': _jenisKelamin,
          'tanggalLahir': Timestamp.fromDate(_tanggalLahir!),
          'namaOrangTua': joinedNames,
          'orangTuaIds': ortuIds,
          'orangTuaNames': ortuNames,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_isImageDeleted) {
          updateData['fotoUrl'] = FieldValue.delete();
        } else if (finalFotoUrl != null) {
          updateData['fotoUrl'] = finalFotoUrl;
        }

        await FirebaseFirestore.instance
            .collection('balita')
            .doc(widget.docId)
            .update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Balita berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan saat memperbarui data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Data Balita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Menyimpan perubahan...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BAGIAN HEADER & FOTO PROFIL ---
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 20),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.blue[50],
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : (_currentImageUrl != null &&
                                                !_isImageDeleted
                                            ? NetworkImage(_currentImageUrl!)
                                            : null),
                                  child:
                                      _imageFile == null &&
                                          (_currentImageUrl == null ||
                                              _isImageDeleted)
                                      ? Icon(
                                          Icons.child_care_rounded,
                                          size: 60,
                                          color: Colors.blue[300],
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  child: InkWell(
                                    onTap: () =>
                                        _showImageSourceActionSheet(context),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMASI DASAR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nama Lengkap Balita',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _namaController,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: 'Masukkan nama balita',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Nama wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  'Jenis Kelamin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _jenisKelamin,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: 'Pilih jenis kelamin',
                                    icon: Icons.wc,
                                  ),
                                  items: ['Laki-laki', 'Perempuan']
                                      .map(
                                        (jk) => DropdownMenuItem(
                                          value: jk,
                                          child: Text(jk),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _jenisKelamin = val),
                                  validator: (value) => value == null
                                      ? 'Pilih jenis kelamin'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  'Tanggal Lahir',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _tanggalLahir ?? DateTime.now(),
                                      firstDate: DateTime(2015),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      setState(
                                        () => _tanggalLahir = pickedDate,
                                      );
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      hint: '',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                    child: Text(
                                      _tanggalLahir == null
                                          ? 'Pilih Tanggal Lahir'
                                          : _formatDate(_tanggalLahir!),
                                      style: TextStyle(
                                        color: _tanggalLahir == null
                                            ? Colors.grey[500]
                                            : Colors.black87,
                                        fontWeight: _tanggalLahir == null
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'KELUARGA / PENDAMPING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Orang Tua / Wali',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    if (_selectedParents.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${_selectedParents.length} Dipilih',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _bukaPencarianOrangTua,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedParents.isEmpty
                                            ? Colors.grey.shade300
                                            : Colors.blue.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.family_restroom_rounded,
                                          color: _selectedParents.isEmpty
                                              ? Colors.grey
                                              : Colors.blue,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _selectedParents.isEmpty
                                              ? Text(
                                                  'Ketuk untuk mencari & memilih',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                  ),
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: _selectedParents.map((
                                                    parent,
                                                  ) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.green,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              parent['name']!,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: Colors.blue.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.blue),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}
