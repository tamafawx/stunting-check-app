// Halaman untuk menampilkan pengelolaan jadwal untuk admin.
// Disini admin bisa membuat jadwal melewati tambah jadwal dan
// mengelola jadwal untuk orang tua bisa melihat.

// Role yang dapat akses:
// - Admin

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'jadwal_tambah.dart';

class KelolaJadwal extends StatefulWidget {
  const KelolaJadwal({super.key});

  @override
  State<KelolaJadwal> createState() => _KelolaJadwalState();
}

class _KelolaJadwalState extends State<KelolaJadwal> {
  String _selectedKategori = 'Semua';

  Future<void> _hapusJadwal(String docId, String judul) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus jadwal "$judul"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('jadwal')
            .doc(docId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus jadwal.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs, {required bool isArsip}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArsip ? Icons.archive_outlined : Icons.event_busy_rounded,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              isArsip ? "Belum ada arsip jadwal." : "Tidak ada jadwal aktif.",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;
        String judul = data['judul'] ?? '-';
        String kategori = data['kategori'] ?? '-';
        String waktuMulai = data['waktuMulai'] ?? '00:00';
        String waktuSelesai = data['waktuSelesai'] ?? '00:00';
        Timestamp? tglTs = data['tanggal'];
        DateTime tanggal = tglTs?.toDate() ?? DateTime.now();
        String tglString = DateFormat('dd MMM yyyy').format(tanggal);

        return Card(
          elevation: isArsip ? 0 : 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isArsip
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none,
          ),
          color: isArsip ? Colors.grey[50] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isArsip
                        ? null
                        : LinearGradient(
                            colors: kategori == 'Posyandu'
                                ? [Colors.blue.shade400, Colors.blue.shade600]
                                : [
                                    Colors.purple.shade400,
                                    Colors.purple.shade600,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isArsip ? Colors.grey[300] : null,
                    shape: BoxShape.circle,
                    boxShadow: isArsip
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  (kategori == 'Posyandu'
                                          ? Colors.blue
                                          : Colors.purple)
                                      .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    kategori == 'Posyandu'
                        ? Icons.group_rounded
                        : Icons.vaccines_rounded,
                    color: isArsip ? Colors.grey.shade600 : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isArsip
                              ? Colors.grey.shade600
                              : Colors.black87,
                          decoration: isArsip
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tglString,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$waktuMulai - $waktuSelesai",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isArsip
                              ? Colors.grey.shade200
                              : (kategori == 'Posyandu'
                                    ? Colors.blue.shade50
                                    : Colors.purple.shade50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isArsip
                                ? Colors.grey.shade400
                                : (kategori == 'Posyandu'
                                      ? Colors.blue.shade200
                                      : Colors.purple.shade200),
                          ),
                        ),
                        child: Text(
                          kategori,
                          style: TextStyle(
                            fontSize: 11,
                            color: isArsip
                                ? Colors.grey.shade600
                                : (kategori == 'Posyandu'
                                      ? Colors.blue.shade700
                                      : Colors.purple.shade700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!isArsip)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormJadwalAdminScreen(
                                docId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () => _hapusJadwal(doc.id, judul),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Kelola Jadwal",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: "Jadwal Aktif"),
              Tab(text: "Arsip Jadwal"),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list_rounded,
                      color: Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    ...['Semua', 'Posyandu', 'Imunisasi'].map((kategori) {
                      bool isSelected = _selectedKategori == kategori;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(kategori),
                          selected: isSelected,
                          selectedColor: Colors.red.shade50,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(
                            color: isSelected
                                ? Colors.red.shade300
                                : Colors.transparent,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedKategori = kategori);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jadwal')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Belum ada jadwal yang dibuat.",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    if (_selectedKategori == 'Semua') return true;
                    var data = doc.data() as Map<String, dynamic>;
                    return data['kategori'] == _selectedKategori;
                  }).toList();

                  List<QueryDocumentSnapshot> aktifDocs = [];
                  List<QueryDocumentSnapshot> arsipDocs = [];

                  DateTime now = DateTime.now();
                  DateTime today = DateTime(now.year, now.month, now.day);

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    Timestamp? tglTs = data['tanggal'];
                    DateTime tanggal = tglTs?.toDate() ?? now;
                    DateTime tglOnly = DateTime(
                      tanggal.year,
                      tanggal.month,
                      tanggal.day,
                    );

                    bool isPast = tglOnly.isBefore(today);

                    if (isPast) {
                      arsipDocs.add(doc);
                    } else {
                      aktifDocs.add(doc);
                    }
                  }

                  // Urutkan jadwal aktif (yang terdekat dengan hari ini duluan)
                  aktifDocs.sort((a, b) {
                    Timestamp tA =
                        (a.data() as Map<String, dynamic>)['tanggal'] ??
                        Timestamp.now();
                    Timestamp tB =
                        (b.data() as Map<String, dynamic>)['tanggal'] ??
                        Timestamp.now();
                    return tA.compareTo(tB);
                  });

                  // Urutkan arsip jadwal (yang paling baru selesai duluan)
                  arsipDocs.sort((a, b) {
                    Timestamp tA =
                        (a.data() as Map<String, dynamic>)['tanggal'] ??
                        Timestamp.now();
                    Timestamp tB =
                        (b.data() as Map<String, dynamic>)['tanggal'] ??
                        Timestamp.now();
                    return tB.compareTo(tA);
                  });

                  return TabBarView(
                    children: [
                      _buildList(aktifDocs, isArsip: false),
                      _buildList(arsipDocs, isArsip: true),
                    ],
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
                builder: (context) => const FormJadwalAdminScreen(),
              ),
            );
          },
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
