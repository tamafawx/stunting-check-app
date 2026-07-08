import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_edukasi_orang_tua.dart';

class EdukasiOrangTuaScreen extends StatefulWidget {
  const EdukasiOrangTuaScreen({super.key});

  @override
  State<EdukasiOrangTuaScreen> createState() => _EdukasiOrangTuaScreenState();
}

class _EdukasiOrangTuaScreenState extends State<EdukasiOrangTuaScreen> {
  String _searchQuery = '';
  String _selectedSort = 'Terbaru';
  bool _isListView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Tema hijau untuk orang tua
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
        backgroundColor: Colors.green,
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sort_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
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
                            color: Colors.green,
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
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isListView
                            ? Icons.grid_view_rounded
                            : Icons.view_list_rounded,
                        color: Colors.green,
                      ),
                      tooltip: 'Ubah Tampilan',
                      onPressed: () {
                        setState(() {
                          _isListView = !_isListView;
                        });
                      },
                    ),
                  ],
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
                    child: CircularProgressIndicator(color: Colors.green),
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
                  return judul.contains(_searchQuery.toLowerCase());
                }).toList();

                // Sort lokal berdasarkan opsi dropdown
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

  Widget _buildVerticalCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String imageUrl,
    String judul,
    String namaPenulis,
    String fotoPenulis,
    String tanggal,
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
              builder: (context) => DetailEdukasiOrangTuaScreen(data: data),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image, size: 50, color: Colors.grey),
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
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage: fotoPenulis.isNotEmpty
                                  ? NetworkImage(fotoPenulis)
                                  : null,
                              child: fotoPenulis.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.green,
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
              builder: (context) => DetailEdukasiOrangTuaScreen(data: data),
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
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                  backgroundColor: Colors.green.withValues(
                                    alpha: 0.2,
                                  ),
                                  backgroundImage: fotoPenulis.isNotEmpty
                                      ? NetworkImage(fotoPenulis)
                                      : null,
                                  child: fotoPenulis.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 12,
                                          color: Colors.green,
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
