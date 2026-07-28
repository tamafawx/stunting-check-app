import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'balita_tambah.dart';
import 'balita_detail.dart';

class KelolaBalita extends StatefulWidget {
  final String role;
  final String fullName;
  const KelolaBalita({super.key, required this.role, required this.fullName});

  @override
  State<KelolaBalita> createState() => _KelolaBalitaState();
}

class _KelolaBalitaState extends State<KelolaBalita> {
  String _searchQuery = '';
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  // Deteksi warna berdasarkan role
  Color get themeColor => widget.role == 'bidan' ? Colors.purple : Colors.blue;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _hapusBalita(String docId, String namaBalita) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Konfirmasi Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus data "$namaBalita"?',
              style: const TextStyle(color: Colors.black87),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('balita').doc(docId).update(
          {'isHidden': true},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data balita berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _calculateAge(dynamic birthDateData) {
    if (birthDateData == null) return "-";
    DateTime birthDate;
    if (birthDateData is Timestamp) {
      birthDate = birthDateData.toDate();
    } else if (birthDateData is String) {
      birthDate = DateTime.tryParse(birthDateData) ?? DateTime.now();
    } else {
      return "-";
    }

    DateTime now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (months < 0) {
      years--;
      months += 12;
    }
    if (now.day < birthDate.day) {
      months--;
      if (months < 0) {
        years--;
        months += 11;
      }
    }

    if (years == 0) {
      return "$months bln";
    }
    return "$years th $months bln";
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Data Balita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('balita')
            .where('isHidden', isEqualTo: false)
            .snapshots(),
        builder: (context, balitaSnapshot) {
          if (balitaSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }
          if (balitaSnapshot.hasError) {
            return const Center(
              child: Text('Terjadi kesalahan saat memuat data.'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pemeriksaan')
                .snapshots(),
            builder: (context, pemeriksaanSnapshot) {
              if (pemeriksaanSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: themeColor),
                );
              }

              var balitaDocs = balitaSnapshot.data?.docs ?? [];
              var pemeriksaanDocs = pemeriksaanSnapshot.data?.docs ?? [];

              Map<String, String> latestStatusMap = {};
              Map<String, DateTime> latestDateMap = {};

              for (var doc in pemeriksaanDocs) {
                var data = doc.data() as Map<String, dynamic>;
                String bId = data['balitaId'] ?? '';
                Timestamp? ts = data['tanggal'];
                if (bId.isNotEmpty && ts != null) {
                  DateTime date = ts.toDate();
                  if (!latestDateMap.containsKey(bId) ||
                      date.isAfter(latestDateMap[bId]!)) {
                    latestDateMap[bId] = date;
                    latestStatusMap[bId] = data['statusStunting'] ?? 'Normal';
                  }
                }
              }

              int countAman = 0;
              int countRendah = 0;
              int countTinggi = 0;

              for (var bDoc in balitaDocs) {
                String statusRaw = (latestStatusMap[bDoc.id] ?? 'Normal')
                    .toLowerCase();
                if (statusRaw.contains('tinggi') ||
                    statusRaw.contains('sangat pendek')) {
                  countTinggi++;
                } else if (statusRaw.contains('sedang') ||
                    statusRaw.contains('pendek')) {
                  countRendah++;
                } else {
                  countAman++;
                }
              }

              var filteredBalita = balitaDocs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                var name = (data['nama'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              filteredBalita.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                String nameA = (dataA['nama'] ?? '').toString().toLowerCase();
                String nameB = (dataB['nama'] ?? '').toString().toLowerCase();

                if (_isAscending) {
                  return nameA.compareTo(nameB);
                } else {
                  return nameB.compareTo(nameA);
                }
              });

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Total Balita",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${balitaDocs.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Balita Terdaftar",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.child_care,
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatusCard(
                              "Aman",
                              countAman,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatusCard(
                              "Risiko Rendah",
                              countRendah,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatusCard(
                              "Risiko Tinggi",
                              countTinggi,
                              Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Daftar Balita",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isAscending = !_isAscending;
                                  });
                                },
                                icon: Icon(
                                  _isAscending
                                      ? Icons.sort_by_alpha
                                      : Icons.sort_by_alpha_outlined,
                                  color: themeColor,
                                  size: 18,
                                ),
                                label: Text(
                                  _isAscending ? 'A-Z' : 'Z-A',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama balita...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (filteredBalita.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Balita tidak ditemukan.',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (filteredBalita.isNotEmpty)
                            ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredBalita.length,
                              itemBuilder: (context, index) {
                                final document = filteredBalita[index];
                                final data =
                                    document.data() as Map<String, dynamic>;
                                final docId = document.id;
                                final nama = data['nama'] ?? 'Tanpa Nama';
                                final jenisKelamin =
                                    data['jenisKelamin'] ?? '-';
                                final usia = _calculateAge(
                                  data['tanggalLahir'],
                                );
                                final String? fotoUrl = data['fotoUrl'];

                                String statusRaw =
                                    latestStatusMap[docId] ?? 'Normal';
                                String statusTampil = "Aman";
                                Color statusColor = Colors.green;

                                if (statusRaw.toLowerCase().contains(
                                      'tinggi',
                                    ) ||
                                    statusRaw.toLowerCase().contains(
                                      'sangat pendek',
                                    )) {
                                  statusTampil = "Risiko Tinggi";
                                  statusColor = Colors.redAccent;
                                } else if (statusRaw.toLowerCase().contains(
                                      'sedang',
                                    ) ||
                                    statusRaw.toLowerCase().contains(
                                      'pendek',
                                    )) {
                                  statusTampil = "Risiko Rendah";
                                  statusColor = Colors.orange;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: Colors.grey.shade100,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 6.0,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailBalita(
                                            docId: docId,
                                            data: data,
                                            role: widget.role,
                                            fullName: widget.fullName,
                                          ),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          jenisKelamin == 'Laki-laki'
                                          ? themeColor.withValues(alpha: 0.15)
                                          : Colors.pink.withValues(alpha: 0.15),
                                      backgroundImage:
                                          fotoUrl != null && fotoUrl.isNotEmpty
                                          ? NetworkImage(fotoUrl)
                                          : null,
                                      child:
                                          (fotoUrl == null || fotoUrl.isEmpty)
                                          ? Icon(
                                              Icons.child_care,
                                              color: jenisKelamin == 'Laki-laki'
                                                  ? themeColor
                                                  : Colors.pink,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '$usia   $jenisKelamin',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            statusTampil,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (widget.role == 'kader') ...[
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.black54,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            onSelected: (value) {
                                              if (value == 'hapus') {
                                                _hapusBalita(docId, nama);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'hapus',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Hapus Data',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.role == 'kader'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TambahBalita()),
                );
              },
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
