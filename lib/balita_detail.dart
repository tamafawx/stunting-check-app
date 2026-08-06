import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'balita_edit.dart';
import 'laporan_balita.dart';
import 'edukasi_detail.dart';
import 'edukasi.dart';

class DetailBalita extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String role;
  final String fullName;

  const DetailBalita({
    super.key,
    required this.docId,
    required this.data,
    required this.role,
    this.fullName = '',
  });

  @override
  State<DetailBalita> createState() => _DetailBalitaState();
}

class _DetailBalitaState extends State<DetailBalita>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _balitaData = {};
  bool _isLoading = true;

  Color get themeColor => widget.role == 'bidan' ? Colors.purple : Colors.blue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _balitaData = widget.data;
    _listenToBalitaChanges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _listenToBalitaChanges() {
    FirebaseFirestore.instance
        .collection('balita')
        .doc(widget.docId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && mounted) {
              setState(() {
                _balitaData = snapshot.data() as Map<String, dynamic>;
                _isLoading = false;
              });
            } else {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
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

  void _showAddCatatanDialog(String pemeriksaanId) {
    final TextEditingController catatanController = TextEditingController();
    bool isSubmitting = false;

    String namaPetugasAsli = widget.fullName.isNotEmpty
        ? widget.fullName
        : (widget.role == 'bidan' ? 'Bidan Desa' : 'Kader Posyandu');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: themeColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Tambah Catatan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: catatanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Catatan / Rekomendasi',
                        hintText: 'Tuliskan saran untuk orang tua...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (catatanController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Catatan harus diisi'),
                                backgroundColor: Colors.amber,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSubmitting = true);

                          try {
                            String fotoPetugasUrl = '';
                            if (widget.fullName.isNotEmpty) {
                              var userQuery = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('fullName', isEqualTo: widget.fullName)
                                  .where('role', isEqualTo: widget.role)
                                  .limit(1)
                                  .get();

                              if (userQuery.docs.isNotEmpty) {
                                fotoPetugasUrl =
                                    userQuery.docs.first.data()['profileUrl'] ??
                                    '';
                              }
                            }

                            await FirebaseFirestore.instance
                                .collection('pemeriksaan')
                                .doc(pemeriksaanId)
                                .update({
                                  'namaPetugas': namaPetugasAsli,
                                  'rolePetugas': widget.role,
                                  'fotoPetugas': fotoPetugasUrl,
                                  'catatan': catatanController.text.trim(),
                                  'waktuCatatan': FieldValue.serverTimestamp(),
                                });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Catatan berhasil ditambahkan'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menambahkan catatan'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setStateDialog(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _hapusCatatan(String pemeriksaanId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('pemeriksaan')
                  .doc(pemeriksaanId)
                  .update({
                    'namaPetugas': FieldValue.delete(),
                    'rolePetugas': FieldValue.delete(),
                    'fotoPetugas': FieldValue.delete(),
                    'catatan': FieldValue.delete(),
                    'waktuCatatan': FieldValue.delete(),
                  });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Catatan berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanSection(
    Map<String, dynamic> latestPemeriksaan,
    String pemeriksaanId,
  ) {
    String catatan = latestPemeriksaan['catatan'] ?? '';
    String namaPetugas = latestPemeriksaan['namaPetugas'] ?? '';
    String rolePetugas = latestPemeriksaan['rolePetugas'] ?? '';
    String fotoPetugas = latestPemeriksaan['fotoPetugas'] ?? '';
    Timestamp? ts = latestPemeriksaan['waktuCatatan'];

    bool hasCatatan = catatan.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Catatan & Rekomendasi Petugas",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (!hasCatatan &&
                (widget.role == 'kader' || widget.role == 'bidan'))
              InkWell(
                onTap: () => _showAddCatatanDialog(pemeriksaanId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: themeColor),
                      const SizedBox(width: 4),
                      Text(
                        "Tambah",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (!hasCatatan)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.speaker_notes_off_outlined, color: Colors.grey),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Belum ada catatan atau rekomendasi dari petugas untuk hasil pengukuran ini.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Builder(
            builder: (context) {
              String tglFormat = '-';
              if (ts != null) {
                DateTime dt = ts.toDate();
                tglFormat =
                    "${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              Color roleColor = rolePetugas == 'bidan'
                  ? Colors.purple
                  : Colors.blue;
              IconData roleIcon = rolePetugas == 'bidan'
                  ? Icons.medical_services_rounded
                  : Icons.health_and_safety_rounded;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          backgroundImage: fotoPetugas.isNotEmpty
                              ? NetworkImage(fotoPetugas)
                              : null,
                          child: fotoPetugas.isEmpty
                              ? Icon(roleIcon, size: 18, color: roleColor)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaPetugas,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${rolePetugas.toUpperCase()}   $tglFormat",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.role == 'kader' || widget.role == 'bidan')
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => _hapusCatatan(pemeriksaanId),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                    Text(
                      catatan,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRekomendasiEdukasi(String currentStatus) {
    String mappedStatus = 'Aman';
    if (currentStatus.toLowerCase().contains("tinggi") ||
        currentStatus.toLowerCase().contains("sangat pendek")) {
      mappedStatus = 'Risiko Tinggi';
    } else if (currentStatus.toLowerCase().contains("sedang") ||
        currentStatus.toLowerCase().contains("pendek") ||
        currentStatus.toLowerCase().contains("rendah")) {
      mappedStatus = 'Risiko Rendah';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Rekomendasi Edukasi",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Edukasi(userId: '', fullName: '', role: widget.role),
                  ),
                );
              },
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('edukasi')
              .where('kategoriStatus', whereIn: ['Semua (Umum)', mappedStatus])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      "Belum ada edukasi terkait.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            var docs = snapshot.data!.docs;
            docs.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              Timestamp tA =
                  dataA['createdAt'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
              Timestamp tB =
                  dataB['createdAt'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
              return tB.compareTo(tA);
            });
            var topDocs = docs.take(3).toList();

            return Column(
              children: topDocs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String judul = data['judul'] ?? 'Tanpa Judul';
                String imageUrl = data['imageUrl'] ?? '';
                String tanggal = '-';

                if (data['createdAt'] != null) {
                  DateTime dt = (data['createdAt'] as Timestamp).toDate();
                  tanggal =
                      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
                }

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailEdukasi(data: data, role: widget.role),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tanggal,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nama =
        _balitaData['nama'] ?? widget.data['nama'] ?? 'Tanpa Nama';
    final String jenisKelamin =
        _balitaData['jenisKelamin'] ?? widget.data['jenisKelamin'] ?? '-';
    final String usiaText = _calculateAge(
      _balitaData['tanggalLahir'] ?? widget.data['tanggalLahir'],
    );
    final String idBalita = "BLT-${widget.docId.substring(0, 5).toUpperCase()}";
    final String? fotoUrl = _balitaData['fotoUrl'] ?? widget.data['fotoUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Detail Balita",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: "Unduh Laporan",
            icon: const Icon(Icons.download_outlined, color: Colors.black87),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Menyiapkan laporan PDF...'),
                      ],
                    ),
                    backgroundColor: themeColor,
                    duration: const Duration(seconds: 2),
                  ),
                );

                await generateLaporanBalita(
                  balitaId: widget.docId,
                  idBalita: idBalita,
                  nama: nama,
                  jenisKelamin: jenisKelamin,
                  usia: usiaText,
                  tanggalLahirData:
                      _balitaData['tanggalLahir'] ??
                      widget.data['tanggalLahir'],
                  fotoUrl: fotoUrl,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengunduh laporan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          if (widget.role == 'kader')
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBalitaScreen(
                      docId: widget.docId,
                      data: _balitaData,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: jenisKelamin == 'Laki-laki'
                        ? themeColor.withValues(alpha: 0.1)
                        : Colors.pink[50],
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: jenisKelamin == 'Laki-laki'
                          ? themeColor.withValues(alpha: 0.2)
                          : Colors.pink[100],
                      backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                          ? NetworkImage(fotoUrl)
                          : null,
                      child: (fotoUrl == null || fotoUrl.isEmpty)
                          ? Icon(
                              Icons.child_care_rounded,
                              size: 44,
                              color: jenisKelamin == 'Laki-laki'
                                  ? themeColor
                                  : Colors.pink[700],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$jenisKelamin, $usiaText",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ID Balita: $idBalita",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              labelColor: themeColor,
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: themeColor,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Ringkasan"),
                Tab(text: "Riwayat"),
                Tab(text: "Grafik"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRingkasanTab(),
                _buildRiwayatTab(),
                _buildGrafikTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where('balitaId', isEqualTo: widget.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Terjadi kesalahan: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Belum ada data pemeriksaan",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  "Silakan input pengukuran terlebih dahulu.",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          Timestamp tA = dataA['tanggal'] ?? Timestamp.now();
          Timestamp tB = dataB['tanggal'] ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        var latestDoc = docs.first.data() as Map<String, dynamic>;
        String latestDocId = docs.first.id;

        String berat = latestDoc['beratBadan'] != null
            ? "${latestDoc['beratBadan']} kg"
            : "-";
        String tinggi = latestDoc['tinggiBadan'] != null
            ? "${latestDoc['tinggiBadan']} cm"
            : "-";
        String kepala = latestDoc['lingkarKepala'] != null
            ? "${latestDoc['lingkarKepala']} cm"
            : "-";
        String lengan = latestDoc['lingkarLengan'] != null
            ? "${latestDoc['lingkarLengan']} cm"
            : "-";

        String tglPemeriksaan = "-";
        if (latestDoc['tanggal'] != null) {
          Timestamp t = latestDoc['tanggal'];
          DateTime dt = t.toDate();
          tglPemeriksaan =
              "${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year}";
        }

        String statusStunting = latestDoc['statusStunting'] ?? "Memproses...";
        Color alertColor = Colors.green;
        Color bgColor = Colors.green.shade50;
        Color borderColor = Colors.green.shade200;
        IconData alertIcon = Icons.check_circle_outline_rounded;
        String saranText =
            "Pertumbuhan balita normal. Pertahankan asupan gizi dan pola asuh yang baik.";

        if (statusStunting.toLowerCase().contains("risiko tinggi") ||
            statusStunting.toLowerCase().contains("sangat pendek")) {
          alertColor = Colors.redAccent;
          bgColor = const Color(0xFFFFF2F2);
          borderColor = const Color(0xFFFFD1D1);
          alertIcon = Icons.warning_amber_rounded;
          saranText =
              "Sangat disarankan untuk segera konsultasi dengan bidan atau dokter anak.";
        } else if (statusStunting.toLowerCase().contains("risiko sedang") ||
            statusStunting.toLowerCase().contains("pendek") ||
            statusStunting.toLowerCase().contains("risiko rendah")) {
          alertColor = Colors.orange;
          bgColor = Colors.orange.shade50;
          borderColor = Colors.orange.shade200;
          alertIcon = Icons.info_outline_rounded;
          saranText =
              "Pertumbuhan perlu dipantau. Disarankan untuk konsultasi gizi dengan kader/bidan.";
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  children: [
                    _buildMeasurementRow(
                      icon: Icons.scale_outlined,
                      label: "Berat Badan Terakhir",
                      value: berat,
                      date: tglPemeriksaan,
                      color: themeColor,
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildMeasurementRow(
                      icon: Icons.straighten_rounded,
                      label: "Tinggi Badan Terakhir",
                      value: tinggi,
                      date: tglPemeriksaan,
                      color: themeColor,
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildMeasurementRow(
                      icon: Icons.face_rounded,
                      label: "Lingkar Kepala",
                      value: kepala,
                      date: tglPemeriksaan,
                      color: themeColor,
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildMeasurementRow(
                      icon: Icons.gesture,
                      label: "Lingkar Lengan",
                      value: lengan,
                      date: tglPemeriksaan,
                      color: Colors.green[600]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Hasil Prediksi Terakhir",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(alertIcon, color: alertColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusStunting,
                            style: TextStyle(
                              color: alertColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Diperbarui: $tglPemeriksaan",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: themeColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        saranText,
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildCatatanSection(latestDoc, latestDocId),

              const SizedBox(height: 24),
              _buildRekomendasiEdukasi(statusStunting),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiwayatTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where('balitaId', isEqualTo: widget.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Terjadi kesalahan: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Belum ada riwayat pengukuran.",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          Timestamp tA = dataA['tanggal'] ?? Timestamp.now();
          Timestamp tB = dataB['tanggal'] ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index].data() as Map<String, dynamic>;

            DateTime dt = (doc['tanggal'] as Timestamp).toDate();
            String formattedDate =
                "${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year}";

            String statusRiwayat = doc['statusStunting'] ?? "Memproses...";
            Color bgStatusColor = Colors.grey.shade100;
            Color textStatusColor = Colors.grey.shade600;

            if (statusRiwayat.toLowerCase().contains("tinggi") ||
                statusRiwayat.toLowerCase().contains("sangat pendek")) {
              bgStatusColor = Colors.red.shade50;
              textStatusColor = Colors.red;
            } else if (statusRiwayat.toLowerCase().contains("sedang") ||
                statusRiwayat.toLowerCase().contains("pendek") ||
                statusRiwayat.toLowerCase().contains("rendah")) {
              bgStatusColor = Colors.orange.shade50;
              textStatusColor = Colors.orange;
            } else if (statusRiwayat.toLowerCase().contains("aman") ||
                statusRiwayat.toLowerCase().contains("normal")) {
              bgStatusColor = Colors.green.shade50;
              textStatusColor = Colors.green;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgStatusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusRiwayat,
                          style: TextStyle(
                            fontSize: 10,
                            color: textStatusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHistoryMetric(
                        "BB",
                        "${doc['beratBadan'] ?? '-'} kg",
                      ),
                      _buildHistoryMetric(
                        "TB",
                        "${doc['tinggiBadan'] ?? '-'} cm",
                      ),
                      _buildHistoryMetric(
                        "LK",
                        "${doc['lingkarKepala'] ?? '-'} cm",
                      ),
                      _buildHistoryMetric(
                        "LILA",
                        "${doc['lingkarLengan'] ?? '-'} cm",
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGrafikTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where('balitaId', isEqualTo: widget.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Data belum memadai untuk membentuk grafik",
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          Timestamp tA = (a.data() as Map)['tanggal'] ?? Timestamp.now();
          Timestamp tB = (b.data() as Map)['tanggal'] ?? Timestamp.now();
          return tA.compareTo(tB);
        });

        List<FlSpot> beratSpots = [];
        List<FlSpot> tinggiSpots = [];

        for (int i = 0; i < docs.length; i++) {
          var data = docs[i].data() as Map<String, dynamic>;
          double berat = double.tryParse(data['beratBadan'].toString()) ?? 0;
          double tinggi = double.tryParse(data['tinggiBadan'].toString()) ?? 0;

          beratSpots.add(FlSpot(i.toDouble(), berat));
          tinggiSpots.add(FlSpot(i.toDouble(), tinggi));
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Kurva Pertumbuhan Balita",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      maxY: 150.0,
                      minY: 0,
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 == 0) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: tinggiSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: beratSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 12, height: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text(
                      "Tinggi Badan (cm)",
                      style: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 12, height: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      "Berat Badan (kg)",
                      style: TextStyle(fontSize: 10),
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

  Widget _buildMeasurementRow({
    required IconData icon,
    required String label,
    required String value,
    required String date,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return "";
  }
}
