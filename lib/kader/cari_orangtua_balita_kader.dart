import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CariOrangTuaScreen extends StatefulWidget {
  final List<Map<String, String>> initialSelection;

  const CariOrangTuaScreen({super.key, required this.initialSelection});

  @override
  State<CariOrangTuaScreen> createState() => _CariOrangTuaScreenState();
}

class _CariOrangTuaScreenState extends State<CariOrangTuaScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Menyimpan data orang tua yang dipilih (ID dan Nama)
  late List<Map<String, String>> _selectedParents;

  @override
  void initState() {
    super.initState();
    // Salin data awal agar tidak merubah data asli sebelum tombol Selesai ditekan
    _selectedParents = List.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id, String name, bool isSelected) {
    setState(() {
      if (isSelected) {
        // Cek agar tidak duplikat
        if (!_selectedParents.any((element) => element['id'] == id)) {
          _selectedParents.add({'id': id, 'name': name});
        }
      } else {
        _selectedParents.removeWhere((element) => element['id'] == id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pilih Orang Tua / Wali',
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
      body: Column(
        children: [
          // Bar Pencarian
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama orang tua...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'orang-tua')
                  // HAPUS BARIS INI: .where('status', isEqualTo: 'aktif')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    'Belum ada data orang tua yang terdaftar.',
                  );
                }

                var rawUsers = snapshot.data!.docs;

                // Filter pencarian lokal DAN Filter status aktif
                var filteredUsers = rawUsers.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = (data['fullName'] ?? '').toString().toLowerCase();
                  var status =
                      data['status'] ??
                      'aktif'; // Jika tidak ada status, anggap aktif

                  bool isMatchSearch = name.contains(
                    _searchQuery.toLowerCase(),
                  );
                  bool isActive = status == 'aktif';

                  return isMatchSearch && isActive;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState(
                    'Tidak ditemukan hasil untuk "$_searchQuery".',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var doc = filteredUsers[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['fullName'] ?? 'Tanpa Nama';
                    String email = data['email'] ?? 'Tidak ada email';
                    String? profileUrl = data['profileUrl'];

                    bool isSelected = _selectedParents.any(
                      (e) => e['id'] == doc.id,
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onChanged: (bool? value) {
                          if (value != null) {
                            _toggleSelection(doc.id, name, value);
                          }
                        },
                        secondary: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          backgroundImage:
                              profileUrl != null && profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                          child: (profileUrl == null || profileUrl.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                  size: 20,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedParents.length} Dipilih',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Kirim kembali data yang dipilih ke halaman sebelumnya
                  Navigator.pop(context, _selectedParents);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
