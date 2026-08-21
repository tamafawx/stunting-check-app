// Menampilkan jadwal posyandu dan imunisasi untuk orang tua.
// Desain modern dengan UI Kartu premium dan preview OpenStreetMap.

// Role yang dapat akses:
// - Orang Tua

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class Jadwal extends StatefulWidget {
  final String role;
  const Jadwal({super.key, this.role = 'orang-tua'});

  @override
  State<Jadwal> createState() => _JadwalState();
}

class _JadwalState extends State<Jadwal> {
  void _tambahKeKalender(
    String judul,
    String keterangan,
    String lokasi,
    DateTime tanggal,
    String waktuMulai,
    String waktuSelesai,
  ) {
    try {
      final List<String> startParts = waktuMulai.split(':');
      final List<String> endParts = waktuSelesai.split(':');

      DateTime startDate = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        int.tryParse(startParts.isNotEmpty ? startParts[0] : '0') ?? 0,
        int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0,
      );

      DateTime endDate = DateTime(
        tanggal.year,
        tanggal.month,
        tanggal.day,
        int.tryParse(endParts.isNotEmpty ? endParts[0] : '0') ?? 0,
        int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
      );

      final Event event = Event(
        title: judul,
        description: keterangan.isNotEmpty
            ? keterangan
            : 'Kegiatan Posyandu / Imunisasi dari aplikasi',
        location: lokasi,
        startDate: startDate,
        endDate: endDate,
        allDay: false,
      );

      Add2Calendar.addEvent2Cal(event).then((success) {
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menambahkan jadwal ke kalender.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memproses kalender.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    Color bgColor = const Color(0xFFF1F8E9);
    List<Color> gradientColors = [const Color(0xFF388E3C), const Color(0xFF66BB6A)];
    Color indicatorColor = Colors.green;

    if (widget.role == 'kader') {
      bgColor = Colors.blue.shade50;
      gradientColors = [Colors.blue.shade700, Colors.blue.shade400];
      indicatorColor = Colors.blue;
    } else if (widget.role == 'bidan') {
      bgColor = Colors.purple.shade50;
      gradientColors = [Colors.purple.shade700, Colors.purple.shade400];
      indicatorColor = Colors.purple;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Jadwal Mendatang",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
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
            .collection('jadwal')
            .where(
              'tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
            )
            .orderBy('tanggal')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: indicatorColor),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: indicatorColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: indicatorColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Belum Ada Jadwal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Jadwal posyandu atau imunisasi\nakan muncul di sini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const ClampingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              String judul = data['judul'] ?? 'Kegiatan Posyandu';
              String kategori = data['kategori'] ?? 'Posyandu';
              String lokasi = data['lokasi'] ?? '-';
              String keterangan = data['keterangan'] ?? '';
              String waktuMulai = data['waktuMulai'] ?? '00:00';
              String waktuSelesai = data['waktuSelesai'] ?? '00:00';

              double? lat = data['latitude'];
              double? lng = data['longitude'];

              Timestamp? tglTs = data['tanggal'];
              DateTime tanggal = tglTs?.toDate() ?? DateTime.now();
              String formatTanggal = DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(tanggal);

              bool isPosyandu = kategori.toLowerCase() == 'posyandu';
              Color themeColor;
              Color lightThemeColor;

              if (widget.role == 'kader') {
                themeColor = isPosyandu ? Colors.blue : Colors.orange;
                lightThemeColor = isPosyandu ? Colors.blue.shade50 : Colors.orange.shade50;
              } else if (widget.role == 'bidan') {
                themeColor = isPosyandu ? Colors.purple : Colors.orange;
                lightThemeColor = isPosyandu ? Colors.purple.shade50 : Colors.orange.shade50;
              } else {
                themeColor = isPosyandu ? Colors.green : Colors.orange;
                lightThemeColor = isPosyandu ? Colors.green.shade50 : Colors.orange.shade50;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER KARTU
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: lightThemeColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPosyandu
                                  ? Icons.group_rounded
                                  : Icons.vaccines_rounded,
                              color: themeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    kategori.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  judul,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BODY CARD (INFORMASI)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.calendar_month_rounded,
                            formatTanggal,
                            themeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time_rounded,
                            "$waktuMulai - $waktuSelesai WIB",
                            themeColor,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.location_on_rounded, lokasi, themeColor),

                          if (keterangan.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      keterangan,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Tombol Tambah ke Kalender
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _tambahKeKalender(
                                judul,
                                keterangan,
                                lokasi,
                                tanggal,
                                waktuMulai,
                                waktuSelesai,
                              ),
                              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                              label: const Text(
                                "Tambahkan ke Kalender",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MAP
                    if (lat != null && lng != null)
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(lat, lng),
                                  initialZoom: 16.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.example.posyandu',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(lat, lng),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color themeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: themeColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
