import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'laporan_riwayat_pemeriksaan.dart';

class RiwayatPemeriksaan extends StatefulWidget {
  final String role;

  const RiwayatPemeriksaan({super.key, required this.role});

  @override
  State<RiwayatPemeriksaan> createState() => _RiwayatPemeriksaanState();
}

class _RiwayatPemeriksaanState extends State<RiwayatPemeriksaan> {
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _documentLimit = 10;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot>? _cachedDocs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        setState(() {
          _documentLimit += 10;
        });
      }
    });
  }

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
    _scrollController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    setState(() {
      _selectedDate = null;
      _documentLimit = 10;
      _cachedDocs = null;
    });
  }

  Color get _themeColor {
    return widget.role == 'bidan' ? Colors.purple : Colors.blue;
  }

  Color get _themeLightColor {
    return widget.role == 'bidan'
        ? const Color(0xFFF3E5F5)
        : const Color(0xFFE3F2FD);
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return PemeriksaanCalendarDialog(
          initialDate: _selectedDate,
          themeColor: _themeColor,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _documentLimit = 10;
        _cachedDocs = null;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
      case 'aman':
        return Colors.green;
      case 'risiko tinggi':
      case 'sangat pendek':
        return Colors.redAccent;
      case 'risiko sedang':
      case 'pendek':
        return Colors.orange;
      default:
        return _themeColor;
    }
  }

  Future<void> _unduhLaporanHarian(DateTime targetDate) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Text('Menyiapkan rekap laporan...'),
          ],
        ),
        backgroundColor: _themeColor,
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      DateTime startOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      var snapPemeriksaan = await FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where(
            'tanggal',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('tanggal', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      List<Map<String, dynamic>> finalData = [];

      for (var doc in snapPemeriksaan.docs) {
        var data = doc.data();
        String bId = data['balitaId'] ?? '';
        String namaBalita = '-';

        if (bId.isNotEmpty) {
          var balitaDoc = await FirebaseFirestore.instance
              .collection('balita')
              .doc(bId)
              .get();
          if (balitaDoc.exists) {
            namaBalita = balitaDoc.data()?['nama'] ?? 'Tanpa Nama';
          }
        }

        data['namaBalita'] = namaBalita;
        finalData.add(data);
      }

      if (finalData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data pemeriksaan di tanggal ini.'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      await generateLaporanPemeriksaanHarian(
        tanggalTerpilih: targetDate,
        dataPemeriksaan: finalData,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        backgroundColor: _themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Unduh Rekap Harian',
            onPressed: () {
              if (_selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan pilih tanggal (hari) terlebih dahulu untuk mengunduh rekap harian.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                _unduhLaporanHarian(_selectedDate!);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
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
                      _documentLimit = 10;
                      _cachedDocs = null;
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
                                _documentLimit = 10;
                                _cachedDocs = null;
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
                        backgroundColor: _themeLightColor,
                        foregroundColor: _themeColor,
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
                        .limit(_documentLimit)
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
                        .limit(_documentLimit)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _cachedDocs = snapshot.data!.docs;
                }

                if (_cachedDocs == null &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _themeColor),
                  );
                }
                if (_cachedDocs == null || _cachedDocs!.isEmpty) {
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
                var rawDocs = _cachedDocs!;
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    String balitaId = data['balitaId'] ?? '';
                    String pemeriksaanId = filteredDocs[index].id;
                    String namaAnak =
                        data['namaBalita'] ?? 'Nama Tidak Diketahui';
                    String status = data['statusStunting'] ?? 'Normal';
                    Timestamp timestamp = data['tanggal'] ?? Timestamp.now();
                    DateTime waktu = timestamp.toDate();
                    String infoWaktu = _selectedDate == null
                        ? "${waktu.day} ${_namaBulan[waktu.month]}   ${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}"
                        : "${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}";

                    String strBb = data['beratBadan'] != null
                        ? "${data['beratBadan']} kg"
                        : "-";
                    String strTb = data['tinggiBadan'] != null
                        ? "${data['tinggiBadan']} cm"
                        : "-";
                    String strLk = data['lingkarKepala'] != null
                        ? "${data['lingkarKepala']} cm"
                        : "-";
                    String strLila = data['lingkarLengan'] != null
                        ? "${data['lingkarLengan']} cm"
                        : "-";

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                      image:
                                          fotoUrl != null && fotoUrl.isNotEmpty
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
                                    const SizedBox(height: 4),
                                    Text(
                                      pemeriksaanId,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontFamily: 'monospace',
                                      ),
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
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDataCol("Berat Badan", strBb),
                              ),
                              Expanded(child: _buildDataCol("Tinggi", strTb)),
                              Expanded(
                                child: _buildDataCol("L. Kepala", strLk),
                              ),
                              Expanded(
                                child: _buildDataCol("L. Lengan", strLila),
                              ),
                            ],
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

  Widget _buildDataCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class PemeriksaanCalendarDialog extends StatefulWidget {
  final DateTime? initialDate;
  final Color themeColor;

  const PemeriksaanCalendarDialog({
    super.key,
    this.initialDate,
    required this.themeColor,
  });

  @override
  State<PemeriksaanCalendarDialog> createState() =>
      _PemeriksaanCalendarDialogState();
}

class _PemeriksaanCalendarDialogState extends State<PemeriksaanCalendarDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Set<DateTime> _eventDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate;
    _fetchEventDates();
  }

  Future<void> _fetchEventDates() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pemeriksaan')
          .get();
      Set<DateTime> dates = {};
      for (var doc in snap.docs) {
        var data = doc.data();
        if (data['tanggal'] != null) {
          DateTime dt = (data['tanggal'] as Timestamp).toDate();
          dates.add(DateTime(dt.year, dt.month, dt.day));
        }
      }
      if (mounted) {
        setState(() {
          _eventDates = dates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: widget.themeColor),
              )
            else
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  Navigator.pop(context, selectedDay);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  DateTime normalized = DateTime(day.year, day.month, day.day);
                  if (_eventDates.contains(normalized)) {
                    return ['event'];
                  }
                  return [];
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: widget.themeColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: widget.themeColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: widget.themeColor),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
