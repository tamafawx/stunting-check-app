// Menampilkan halaman edukasi yang tersedia dan juga dapat dibaca
// nantinya pada halaman detail edukasi. Untuk tiap role ada juga
// yang bisa menghapus konten edukasi secara keseluruhan (admin)
// dan juga sendiri (kader dan bidan), sedangkan orang tua hanya membaca.

// Role yang dapat akses:
// - Admin
// - Kader
// - Bidan
// - Orang Tua

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edukasi_detail.dart';
import 'edukasi_tambah.dart';

class Edukasi extends StatefulWidget {
  final String userId;
  final String fullName;
  final String role;

  const Edukasi({
    super.key,
    required this.userId,
    required this.fullName,
    required this.role,
  });

  @override
  State<Edukasi> createState() => _EdukasiState();
}

class _EdukasiState extends State<Edukasi> {
  String _searchQuery = '';
  String _selectedSort = 'Terbaru';
  String _selectedTarget = 'Semua Target';
  bool _isListView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _hapusEdukasi(
    BuildContext context,
    String docId,
    String judul,
    String penulis,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Konfirmasi Hapus",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus materi edukasi "$judul"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('edukasi')
                      .doc(docId)
                      .delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Edukasi "$judul" berhasil dihapus.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Terjadi kesalahan saat menghapus edukasi.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Hapus",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color mainThemeColor = (widget.role == 'admin')
        ? Colors.red
        : (widget.role == 'kader')
        ? Colors.blue
        : (widget.role == 'bidan')
        ? Colors.purple
        : (widget.role == 'orang-tua')
        ? Colors.green
        : Colors.grey;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Pojok Edukasi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: mainThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton:
          (widget.role != 'orang-tua' && widget.role != 'kader')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TambahEdukasi(
                      userId: widget.userId,
                      fullName: widget.fullName,
                      role: widget.role,
                    ),
                  ),
                );
              },
              backgroundColor: mainThemeColor,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari judul edukasi...',
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_alt_rounded,
                              color: mainThemeColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedTarget,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedTarget = newValue;
                                  });
                                }
                              },
                              items:
                                  <String>[
                                    'Semua Target',
                                    'Semua (Umum)',
                                    'Aman',
                                    'Risiko Rendah',
                                    'Risiko Tinggi',
                                  ].map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sort_rounded,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedSort,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSort = newValue;
                                  });
                                }
                              },
                              items:
                                  <String>[
                                    'Terbaru',
                                    'Terlama',
                                    'A-Z',
                                    'Z-A',
                                  ].map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isListView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            color: mainThemeColor,
                          ),
                          tooltip: 'Ubah Tampilan',
                          onPressed: () {
                            setState(() {
                              _isListView = !_isListView;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('edukasi')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: mainThemeColor),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Terjadi kesalahan saat memuat data.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var rawEdukasi = snapshot.data!.docs;
                var filteredEdukasi = rawEdukasi.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String judul = (data['judul'] ?? '').toString().toLowerCase();
                  String targetStatus =
                      data['kategoriStatus'] ?? 'Semua (Umum)';

                  bool matchSearch = judul.contains(_searchQuery.toLowerCase());
                  bool matchTarget =
                      _selectedTarget == 'Semua Target' ||
                      targetStatus == _selectedTarget;

                  return matchSearch && matchTarget;
                }).toList();

                filteredEdukasi.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  if (_selectedSort == 'A-Z') {
                    String titleA = (dataA['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    String titleB = (dataB['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    return titleA.compareTo(titleB);
                  } else if (_selectedSort == 'Z-A') {
                    String titleA = (dataA['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    String titleB = (dataB['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    return titleB.compareTo(titleA);
                  } else if (_selectedSort == 'Terbaru') {
                    Timestamp tA =
                        dataA['createdAt'] ??
                        Timestamp.fromMillisecondsSinceEpoch(0);
                    Timestamp tB =
                        dataB['createdAt'] ??
                        Timestamp.fromMillisecondsSinceEpoch(0);
                    return tB.compareTo(tA);
                  } else {
                    Timestamp tA =
                        dataA['createdAt'] ??
                        Timestamp.fromMillisecondsSinceEpoch(0);
                    Timestamp tB =
                        dataB['createdAt'] ??
                        Timestamp.fromMillisecondsSinceEpoch(0);
                    return tA.compareTo(tB);
                  }
                });

                if (filteredEdukasi.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredEdukasi.length,
                  itemBuilder: (context, index) {
                    var document = filteredEdukasi[index];
                    var data = document.data() as Map<String, dynamic>;
                    String docId = document.id;
                    String judul = data['judul'] ?? 'Tanpa Judul';
                    String namaPenulis = data['namaPenulis'] ?? 'Kader';
                    String penulisId = data['penulisId'] ?? '';
                    String imageUrl = data['imageUrl'] ?? '';
                    String fotoPenulis = data['fotoPenulis'] ?? '';
                    Timestamp? createdAt = data['createdAt'];
                    String tanggal = '-';
                    if (createdAt != null) {
                      DateTime dt = createdAt.toDate();
                      tanggal = "${dt.day}/${dt.month}/${dt.year}";
                    }
                    bool canDelete =
                        (widget.role == 'admin') ||
                        ((widget.role == 'kader' || widget.role == 'bidan') &&
                            penulisId == widget.userId);

                    if (_isListView) {
                      return _buildHorizontalCard(
                        context: context,
                        data: data,
                        docId: docId,
                        imageUrl: imageUrl,
                        judul: judul,
                        namaPenulis: namaPenulis,
                        fotoPenulis: fotoPenulis,
                        tanggal: tanggal,
                        canDelete: canDelete,
                        themeColor: mainThemeColor,
                      );
                    } else {
                      return _buildVerticalCard(
                        context: context,
                        data: data,
                        docId: docId,
                        imageUrl: imageUrl,
                        judul: judul,
                        namaPenulis: namaPenulis,
                        fotoPenulis: fotoPenulis,
                        tanggal: tanggal,
                        canDelete: canDelete,
                        themeColor: mainThemeColor,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String docId,
    required String imageUrl,
    required String judul,
    required String namaPenulis,
    required String fotoPenulis,
    required String tanggal,
    required bool canDelete,
    required Color themeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailEdukasi(data: data, role: widget.role),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
                if (canDelete)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () =>
                            _hapusEdukasi(context, docId, judul, namaPenulis),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: themeColor.withValues(alpha: .2),
                              backgroundImage: fotoPenulis.isNotEmpty
                                  ? NetworkImage(fotoPenulis)
                                  : null,
                              child: fotoPenulis.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 14,
                                      color: themeColor,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                namaPenulis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        tanggal,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String docId,
    required String imageUrl,
    required String judul,
    required String namaPenulis,
    required String fotoPenulis,
    required String tanggal,
    required bool canDelete,
    required Color themeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailEdukasi(data: data, role: widget.role),
            ),
          );
        },
        child: SizedBox(
          height: 110,
          child: Row(
            children: [
              Container(
                width: 110,
                height: 110,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                      )
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              judul,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canDelete)
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 4,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => _hapusEdukasi(
                                context,
                                docId,
                                judul,
                                namaPenulis,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: themeColor.withValues(
                                    alpha: .2,
                                  ),
                                  backgroundImage: fotoPenulis.isNotEmpty
                                      ? NetworkImage(fotoPenulis)
                                      : null,
                                  child: fotoPenulis.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 12,
                                          color: themeColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    namaPenulis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            tanggal,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Konten edukasi tidak ditemukan.',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
