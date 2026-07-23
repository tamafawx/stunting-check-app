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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Kelola Jadwal",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
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
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Kategori:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedKategori,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedKategori = newValue);
                    }
                  },
                  items: <String>['Semua', 'Posyandu', 'Imunisasi']
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
          ),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
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

                docs.sort((a, b) {
                  Timestamp tA =
                      (a.data() as Map<String, dynamic>)['tanggal'] ??
                      Timestamp.now();
                  Timestamp tB =
                      (b.data() as Map<String, dynamic>)['tanggal'] ??
                      Timestamp.now();
                  return tA.compareTo(tB);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada jadwal di kategori ini.'),
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
                    String tglString = DateFormat(
                      'dd MMM yyyy',
                    ).format(tanggal);
                    bool isPast = tanggal.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isPast ? Colors.grey[100] : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPast
                                ? Colors.grey[300]
                                : Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            kategori == 'Posyandu'
                                ? Icons.group_rounded
                                : Icons.vaccines_rounded,
                            color: isPast ? Colors.grey : Colors.red,
                          ),
                        ),
                        title: Text(
                          judul,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "$tglString • $waktuMulai - $waktuSelesai",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kategori == 'Posyandu'
                                    ? Colors.blue[50]
                                    : Colors.purple[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kategori,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kategori == 'Posyandu'
                                      ? Colors.blue
                                      : Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 20,
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
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _hapusJadwal(doc.id, judul),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormJadwalAdminScreen(),
            ),
          );
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
