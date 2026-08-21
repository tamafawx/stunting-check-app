import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'balita_detail.dart';

class Balita extends StatefulWidget {
  final String userId;

  const Balita({super.key, required this.userId});

  @override
  State<Balita> createState() => _BalitaState();
}

class _BalitaState extends State<Balita> {
  String? _selectedBalitaId;
  bool _hasUserInteracted = false;
  final ScrollController _miniProfileScrollController = ScrollController();

  @override
  void dispose() {
    _miniProfileScrollController.dispose();
    super.dispose();
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
      return "$months Bulan";
    }
    return "$years Tahun $months Bulan";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        title: const Text(
          'Anak Saya',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('balita')
            .where('orangTuaIds', arrayContains: widget.userId)
            .where('isHidden', isEqualTo: false)
            .snapshots(),
        builder: (context, balitaSnapshot) {
          if (balitaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (balitaSnapshot.hasError ||
              !balitaSnapshot.hasData ||
              balitaSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data anak.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pemeriksaan')
                .snapshots(),
            builder: (context, pemeriksaanSnapshot) {
              if (pemeriksaanSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              var balitaDocs = balitaSnapshot.data!.docs;
              var pemeriksaanDocs = pemeriksaanSnapshot.data?.docs ?? [];

              Map<String, Map<String, dynamic>> latestPemeriksaanMap = {};
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
                    latestPemeriksaanMap[bId] = data;
                  }
                }
              }

              String? effectiveSelectedId = _hasUserInteracted
                  ? _selectedBalitaId
                  : (balitaDocs.isNotEmpty ? balitaDocs[0].id : null);

              var filteredBalitaDocs = balitaDocs;
              if (effectiveSelectedId != null) {
                filteredBalitaDocs = balitaDocs
                    .where((doc) => doc.id == effectiveSelectedId)
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (balitaDocs.length > 1) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        "Anak/Balita anda yang terdaftar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 95,
                      child: ListView.builder(
                        controller: _miniProfileScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: balitaDocs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: _buildMiniProfile(
                              balitaDocs[index],
                              false,
                              effectiveSelectedId,
                              context,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredBalitaDocs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            children: [
                              _buildChildCard(
                                context,
                                filteredBalitaDocs[index],
                                latestPemeriksaanMap,
                                double.infinity,
                              ),
                              const SizedBox(height: 16),
                              _buildChartCard(
                                filteredBalitaDocs[index].id,
                                pemeriksaanDocs,
                              ),
                              const SizedBox(height: 16),
                              _buildRiwayatCard(
                                context,
                                filteredBalitaDocs[index],
                                pemeriksaanDocs,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniProfile(
    DocumentSnapshot doc,
    bool isSingle,
    String? effectiveSelectedId,
    BuildContext context,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final nama = data['nama'] ?? 'Tanpa Nama';
    final fotoUrl = data['fotoUrl'];
    final idBalita = doc.id;
    final usia = _calculateAge(data['tanggalLahir']);
    final jenisKelamin = data['jenisKelamin'] ?? '-';

    Color jkColor = jenisKelamin == 'Laki-laki'
        ? Colors.lightBlue
        : Colors.pinkAccent;

    bool isSelected = effectiveSelectedId == idBalita;

    return GestureDetector(
      onTap: () {
        if (!isSingle) {
          setState(() {
            _hasUserInteracted = true;
            _selectedBalitaId = isSelected ? null : idBalita;
          });
        }
      },
      child: Container(
        width: isSingle
            ? double.infinity
            : MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: jkColor.withValues(alpha: 0.1),
              backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                  ? NetworkImage(fotoUrl)
                  : null,
              child: (fotoUrl == null || fotoUrl.isEmpty)
                  ? Icon(Icons.child_care_rounded, color: jkColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: $idBalita",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usia,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    DocumentSnapshot document,
    Map<String, Map<String, dynamic>> latestPemeriksaanMap,
    double width,
  ) {
    final data = document.data() as Map<String, dynamic>;
    final docId = document.id;

    final nama = data['nama'] ?? 'Tanpa Nama';
    final jenisKelamin = data['jenisKelamin'] ?? '-';
    final usia = _calculateAge(data['tanggalLahir']);
    final String? fotoUrl = data['fotoUrl'];

    Map<String, dynamic>? latestPemeriksaan = latestPemeriksaanMap[docId];
    String statusRaw = latestPemeriksaan?['statusStunting'] ?? 'Belum Diukur';

    final bb = latestPemeriksaan?['beratBadan'];
    final tb = latestPemeriksaan?['tinggiBadan'];
    final lk = latestPemeriksaan?['lingkarKepala'];
    final lila = latestPemeriksaan?['lingkarLengan'];
    String statusTampil = statusRaw;
    Color statusBgColor = Colors.grey.shade100;
    Color statusTextColor = Colors.grey.shade600;
    IconData statusIcon = Icons.help_outline_rounded;

    if (statusRaw.toLowerCase().contains('tinggi') ||
        statusRaw.toLowerCase().contains('sangat pendek')) {
      statusTampil = "Risiko Tinggi";
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
    } else if (statusRaw.toLowerCase().contains('sedang') ||
        statusRaw.toLowerCase().contains('pendek')) {
      statusTampil = "Risiko Rendah";
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      statusIcon = Icons.info_outline_rounded;
    } else if (statusRaw.toLowerCase() != 'belum diukur') {
      statusTampil = "Aman";
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green;
      statusIcon = Icons.check_circle_outline_rounded;
    }

    Color jkColor = jenisKelamin == 'Laki-laki'
        ? Colors.lightBlue
        : Colors.pinkAccent;
    IconData jkIcon = jenisKelamin == 'Laki-laki' ? Icons.male : Icons.female;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailBalita(docId: docId, data: data, role: 'orang-tua'),
          ),
        );
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: jkColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: jkColor.withValues(alpha: 0.1),
                    backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                        ? NetworkImage(fotoUrl)
                        : null,
                    child: (fotoUrl == null || fotoUrl.isEmpty)
                        ? Icon(
                            Icons.child_care_rounded,
                            size: 36,
                            color: jkColor.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.cake, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            usia,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(jkIcon, size: 14, color: jkColor),
                          const SizedBox(width: 6),
                          Text(
                            jenisKelamin,
                            style: TextStyle(
                              fontSize: 13,
                              color: jkColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.monitor_weight_outlined,
                    label: "Berat",
                    value: bb != null ? "$bb kg" : "-",
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.height_rounded,
                    label: "Tinggi",
                    value: tb != null ? "$tb cm" : "-",
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.face_rounded,
                    label: "Kepala",
                    value: lk != null ? "$lk cm" : "-",
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.accessibility_new_rounded,
                    label: "Lengan",
                    value: lila != null ? "$lila cm" : "-",
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status Gizi Terakhir:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusTextColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusTextColor),
                      const SizedBox(width: 6),
                      Text(
                        statusTampil,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String balitaId, List<DocumentSnapshot> allPemeriksaanDocs) {
    var docs = allPemeriksaanDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['balitaId'] == balitaId;
    }).toList();

    if (docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Belum ada data pemeriksaan untuk grafik.",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    docs.sort((a, b) {
      Timestamp tA = (a.data() as Map)['tanggal'] ?? Timestamp.now();
      Timestamp tB = (b.data() as Map)['tanggal'] ?? Timestamp.now();
      return tA.compareTo(tB);
    });

    List<FlSpot> beratSpots = [];
    List<FlSpot> tinggiSpots = [];
    List<FlSpot> kepalaSpots = [];
    List<FlSpot> lenganSpots = [];

    for (int i = 0; i < docs.length; i++) {
      var data = docs[i].data() as Map<String, dynamic>;
      double berat = double.tryParse(data['beratBadan'].toString()) ?? 0;
      double tinggi = double.tryParse(data['tinggiBadan'].toString()) ?? 0;
      double kepala = double.tryParse(data['lingkarKepala'].toString()) ?? 0;
      double lengan = double.tryParse(data['lingkarLengan'].toString()) ?? 0;

      beratSpots.add(FlSpot(i.toDouble(), berat));
      tinggiSpots.add(FlSpot(i.toDouble(), tinggi));
      kepalaSpots.add(FlSpot(i.toDouble(), kepala));
      lenganSpots.add(FlSpot(i.toDouble(), lengan));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Grafik Pertumbuhan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.left,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
          SizedBox(
            height: 200,
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100 || value == 150) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            (value.toInt() + 1).toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
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
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: beratSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: kepalaSpots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: lenganSpots,
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegend(Colors.blue, "Berat"),
              _buildLegend(Colors.orange, "Tinggi"),
              _buildLegend(Colors.purple, "Kepala"),
              _buildLegend(Colors.teal, "Lengan"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ],
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
      "Desember"
    ];
    return months[month - 1];
  }

  Widget _buildRiwayatCard(
    BuildContext context,
    DocumentSnapshot balitaDoc,
    List<DocumentSnapshot> allPemeriksaanDocs,
  ) {
    String balitaId = balitaDoc.id;
    var docs = allPemeriksaanDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['balitaId'] == balitaId;
    }).toList();

    docs.sort((a, b) {
      Timestamp tA = (a.data() as Map)['tanggal'] ?? Timestamp.now();
      Timestamp tB = (b.data() as Map)['tanggal'] ?? Timestamp.now();
      return tB.compareTo(tA);
    });

    if (docs.isEmpty) {
      return const SizedBox.shrink();
    }

    bool hasMore = docs.length > 3;
    var displayDocs = docs.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Riwayat Pemeriksaan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.left,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
          ...displayDocs.map((docSnapshot) {
            var doc = docSnapshot.data() as Map<String, dynamic>;
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
          }).toList(),
          if (hasMore)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBalita(
                      docId: balitaId,
                      data: balitaDoc.data() as Map<String, dynamic>,
                      role: 'orang-tua',
                      initialTabIndex: 1, // To history tab
                    ),
                  ),
                );
              },
              child: const Text(
                "Tampil semua riwayat",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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
}
