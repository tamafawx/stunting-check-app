import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatPemeriksaan extends StatefulWidget {
  // Tambahkan property role untuk menyesuaikan tema
  final String role;

  // Berikan default value 'kader' jika tidak di-pass (untuk kompatibilitas)
  const RiwayatPemeriksaan({super.key, required this.role});

  @override
  State<RiwayatPemeriksaan> createState() => _RiwayatPemeriksaanState();
}

class _RiwayatPemeriksaanState extends State<RiwayatPemeriksaan> {
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _namaBulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatTanggal(DateTime date) {
    return "${date.day} ${_namaBulan[date.month]} ${date.year}";
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  // Helper untuk mendapatkan warna tema berdasarkan role
  Color get _themeColor {
    return widget.role == 'bidan' ? Colors.purple : Colors.blue;
  }

  // Helper untuk mendapatkan warna background sekunder berdasarkan role
  Color get _themeLightColor {
    return widget.role == 'bidan'
        ? const Color(0xFFF3E5F5)
        : const Color(0xFFE3F2FD); // purple[50] : blue[50]
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _themeColor, // Gunakan warna tema
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'risiko tinggi':
      case 'sangat pendek':
        return Colors.redAccent;
      case 'risiko sedang':
      case 'pendek':
        return Colors.orange;
      default:
        return _themeColor; // Fallback ke warna tema
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Riwayat Pemeriksaan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _themeColor, // Gunakan warna tema
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
                    hintText: 'Cari nama balita...',
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Menampilkan Data:",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _selectedDate == null
                                  ? "Semua Waktu"
                                  : _formatTanggal(_selectedDate!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            if (_selectedDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: InkWell(
                                  onTap: _resetFilter,
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pilihTanggal(context),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text("Pilih Hari"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _themeLightColor, // Gunakan warna light tema
                        foregroundColor: _themeColor, // Gunakan warna tema
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedDate == null
                  ? FirebaseFirestore.instance
                        .collection('pemeriksaan')
                        .orderBy('tanggal', descending: true)
                        .limit(50) // Menyamakan dengan riwayat bidan
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('pemeriksaan')
                        .where(
                          'tanggal',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              0,
                              0,
                              0,
                            ),
                          ),
                        )
                        .where(
                          'tanggal',
                          isLessThanOrEqualTo: Timestamp.fromDate(
                            DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              23,
                              59,
                              59,
                            ),
                          ),
                        )
                        .orderBy('tanggal', descending: true)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _themeColor),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDate == null
                              ? "Belum ada riwayat pemeriksaan."
                              : "Tidak ada riwayat pada tanggal ini.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                var rawDocs = snapshot.data!.docs;
                var filteredDocs = rawDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = (data['namaBalita'] ?? '')
                      .toString()
                      .toLowerCase();
                  return nama.contains(_searchQuery.toLowerCase());
                }).toList();
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Pencarian tidak ditemukan.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    String balitaId = data['balitaId'] ?? '';
                    String namaAnak =
                        data['namaBalita'] ?? 'Nama Tidak Diketahui';
                    String status = data['statusStunting'] ?? 'Normal';
                    Timestamp timestamp = data['tanggal'] ?? Timestamp.now();
                    DateTime waktu = timestamp.toDate();
                    String infoWaktu = _selectedDate == null
                        ? "${waktu.day} ${_namaBulan[waktu.month]} ${waktu.year} - ${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}"
                        : "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('balita')
                                .doc(balitaId)
                                .get(),
                            builder: (context, balitaSnapshot) {
                              String? fotoUrl;
                              if (balitaSnapshot.hasData &&
                                  balitaSnapshot.data!.exists) {
                                var balitaData =
                                    balitaSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                fotoUrl = balitaData['fotoUrl'];
                              }
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  image: fotoUrl != null && fotoUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(fotoUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (fotoUrl == null || fotoUrl.isEmpty)
                                    ? Center(
                                        child: Icon(
                                          Icons.child_care,
                                          color: _getStatusColor(status),
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaAnak,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      infoWaktu,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
