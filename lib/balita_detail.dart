import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'balita_edit.dart';

class DetailBalita extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String role;

  const DetailBalita({
    super.key,
    required this.docId,
    required this.data,
    required this.role,
  });

  @override
  State<DetailBalita> createState() => _DetailBalitaState();
}

class _DetailBalitaState extends State<DetailBalita>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _balitaData = {};
  bool _isLoading = true;

  // Setel warna dinamis berdasarkan role
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
          // Tombol Edit HANYA jika kader
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

        String statusStunting =
            latestDoc['statusStunting'] ?? "Tidak Diketahui";

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
            statusStunting.toLowerCase().contains("pendek")) {
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
                    if (alertColor == Colors.redAccent)
                      SizedBox(
                        width: 60,
                        height: 30,
                        child: CustomPaint(painter: SparklinePainter()),
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Pemeriksa: Kader",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      key: const ValueKey("ChartContainer"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kurva Pertumbuhan (Tinggi Badan / Usia)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: GrowthChartPainter(
                  themeColor: themeColor,
                ), // Pass themeColor ke Canvas Painter
              ),
            ),
          ],
        ),
      ),
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

class SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintDot = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.4);
    canvas.drawPath(path, paintLine);
    canvas.drawCircle(Offset(0, size.height * 0.3), 3, paintDot);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 3, paintDot);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 3, paintDot);
    canvas.drawCircle(Offset(size.width, size.height * 0.4), 3, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GrowthChartPainter extends CustomPainter {
  final Color themeColor;

  GrowthChartPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    for (int i = 1; i < 5; i++) {
      double x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (int i = 1; i < 5; i++) {
      double y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final greenLimitPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final redLimitPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pathUpper = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.5,
        size.width * 0.7,
        size.height * 0.25,
        size.width,
        size.height * 0.1,
      );
    final pathLower = Path()
      ..moveTo(0, size.height * 0.95)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.75,
        size.width * 0.7,
        size.height * 0.55,
        size.width,
        size.height * 0.4,
      );

    canvas.drawPath(pathUpper, greenLimitPaint);
    canvas.drawPath(pathLower, redLimitPaint);

    final babyPaint = Paint()
      ..color =
          themeColor // Warna garis mengikuti role
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final babyDotPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;

    final babyPath = Path()
      ..moveTo(0, size.height * 0.9)
      ..lineTo(size.width * 0.2, size.height * 0.78)
      ..lineTo(size.width * 0.4, size.height * 0.72)
      ..lineTo(size.width * 0.6, size.height * 0.62)
      ..lineTo(size.width * 0.8, size.height * 0.65);

    canvas.drawPath(babyPath, babyPaint);
    canvas.drawCircle(Offset(0, size.height * 0.9), 4, babyDotPaint);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.78),
      4,
      babyDotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.72),
      4,
      babyDotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.62),
      4,
      babyDotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.65),
      5,
      babyDotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
