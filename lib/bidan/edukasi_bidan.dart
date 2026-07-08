import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'detail_edukasi_bidan.dart';
import 'tambah_edukasi_bidan.dart';

class EdukasiBidan extends StatefulWidget {
  final String userId;
  final String fullName;

  const EdukasiBidan({super.key, required this.userId, required this.fullName});

  @override
  State<EdukasiBidan> createState() => _EdukasiBidanState();
}

class _EdukasiBidanState extends State<EdukasiBidan> {
  String _searchQuery = '';
  String _selectedOwner = 'Semua';
  String _selectedSort = 'Terbaru'; // Default: Tanggal Terbaru
  bool _isListView = false; // false = Card Vertikal, true = Card Horizontal
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteEdukasi(
    BuildContext context,
    String docId,
    String title,
  ) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus materi edukasi "$title"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('edukasi')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Edukasi "$title" berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan saat menghapus edukasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
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
            child: Column(
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
                      const Icon(
                        Icons.filter_list,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pemilik:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedOwner,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.purple,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedOwner = newValue;
                            });
                          }
                        },
                        items: <String>['Semua', 'Milik Saya', 'Orang Lain']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Urutkan:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedSort,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.purple,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSort = newValue;
                            });
                          }
                        },
                        items: <String>['Terbaru', 'Terlama', 'A-Z', 'Z-A']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isListView = !_isListView;
                          });
                        },
                        icon: Icon(
                          _isListView
                              ? Icons.grid_view_rounded
                              : Icons.view_list_rounded,
                          color: Colors.purple,
                          size: 20,
                        ),
                        label: Text(
                          _isListView ? 'Card Vertikal' : 'Card Horizontal',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
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
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
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
                  String penulisId = (data['penulisId'] ?? '').toString();

                  bool matchesSearch = judul.contains(
                    _searchQuery.toLowerCase(),
                  );
                  bool matchesOwner = true;

                  if (_selectedOwner == 'Milik Saya') {
                    matchesOwner = penulisId == widget.userId;
                  } else if (_selectedOwner == 'Orang Lain') {
                    matchesOwner = penulisId != widget.userId;
                  }

                  return matchesSearch && matchesOwner;
                }).toList();

                // Sort locally based on date or alphabetical selection to avoid composite indexing errors
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
                    // 'Terlama'
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

                    if (_isListView) {
                      return _buildHorizontalCard(
                        context,
                        data,
                        docId,
                        imageUrl,
                        judul,
                        namaPenulis,
                        fotoPenulis,
                        tanggal,
                        penulisId == widget.userId,
                      );
                    } else {
                      return _buildVerticalCard(
                        context,
                        data,
                        docId,
                        imageUrl,
                        judul,
                        namaPenulis,
                        fotoPenulis,
                        tanggal,
                        penulisId == widget.userId,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahEdukasiBidan(
                userId: widget.userId,
                fullName: widget.fullName,
              ),
            ),
          );
        },
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildVerticalCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String imageUrl,
    String judul,
    String namaPenulis,
    String fotoPenulis,
    String tanggal,
    bool isMilikSaya,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEdukasiBidan(data: data),
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
                if (isMilikSaya)
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
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteEdukasi(context, docId, judul),
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
                  // Spacing spaceBetween for Nama and Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.purple.withOpacity(0.2),
                              backgroundImage: fotoPenulis.isNotEmpty
                                  ? NetworkImage(fotoPenulis)
                                  : null,
                              child: fotoPenulis.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.purple,
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

  Widget _buildHorizontalCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String imageUrl,
    String judul,
    String namaPenulis,
    String fotoPenulis,
    String tanggal,
    bool isMilikSaya,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEdukasiBidan(data: data),
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
                          if (isMilikSaya)
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 4,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _deleteEdukasi(context, docId, judul),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Spacing spaceBetween for Nama and Tanggal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.purple.withOpacity(
                                    0.2,
                                  ),
                                  backgroundImage: fotoPenulis.isNotEmpty
                                      ? NetworkImage(fotoPenulis)
                                      : null,
                                  child: fotoPenulis.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 12,
                                          color: Colors.purple,
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
