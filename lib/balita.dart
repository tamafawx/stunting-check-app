// Menampilkan data balita yang sudah di atur oleh kader sesuai dengan
// database. Nantinya halaman ini akan menampilkan data anak mereka saja.

// Role yang dapat akses:
// - Orang Tua

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BalitaOrangTuaScreen extends StatefulWidget {
  final String userId;

  const BalitaOrangTuaScreen({super.key, required this.userId});

  @override
  State<BalitaOrangTuaScreen> createState() => _BalitaOrangTuaScreenState();
}

class _BalitaOrangTuaScreenState extends State<BalitaOrangTuaScreen> {
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
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text(
          'Anak Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('balita')
            .where('orangTuaIds', arrayContains: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Terjadi kesalahan memuat data.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final balitaDoc = snapshot.data!.docs[index];
              return _buildBalitaCard(balitaDoc);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.child_care_rounded,
              size: 80,
              color: Colors.green[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Data Anak',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Silakan hubungi Kader Posyandu untuk mendaftarkan dan menghubungkan data anak Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalitaCard(DocumentSnapshot balitaDoc) {
    final data = balitaDoc.data() as Map<String, dynamic>;
    final nama = data['nama'] ?? 'Tanpa Nama';
    final jenisKelamin = data['jenisKelamin'] ?? '-';
    final fotoUrl = data['fotoUrl'];
    final usia = _calculateAge(data['tanggalLahir']);

    final isLaki = jenisKelamin == 'Laki-laki';
    final themeColor = isLaki ? Colors.blue : Colors.pink;
    final bgFotoColor = isLaki ? Colors.blue[50] : Colors.pink[50];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Detail perkembangan anak akan segera hadir!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgFotoColor,
                          shape: BoxShape.circle,
                          image:
                              fotoUrl != null && fotoUrl.toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(fotoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: fotoUrl == null || fotoUrl.toString().isEmpty
                            ? Icon(
                                Icons.child_care_rounded,
                                size: 36,
                                color: themeColor.withOpacity(0.5),
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
                              Icon(
                                Icons.cake_rounded,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                usia,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isLaki ? Icons.male : Icons.female,
                                size: 14,
                                color: themeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                jenisKelamin,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[300],
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[100], thickness: 2, height: 1),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status Gizi Terakhir:",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildStatusPemeriksaan(balitaDoc.id),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPemeriksaan(String balitaId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan')
          .where('balitaId', isEqualTo: balitaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.green,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildStatusBadge(
            "Belum Diukur",
            Colors.grey,
            Icons.help_outline_rounded,
          );
        }

        var docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          Timestamp timeA =
              (a.data() as Map<String, dynamic>)['createdAt'] ??
              Timestamp.now();
          Timestamp timeB =
              (b.data() as Map<String, dynamic>)['createdAt'] ??
              Timestamp.now();
          return timeB.compareTo(timeA);
        });

        final latestData = docs.first.data() as Map<String, dynamic>;
        String rawStatus =
            (latestData['status'] ??
                    latestData['statusGizi'] ??
                    latestData['kesimpulan'] ??
                    latestData['statusStunting'] ??
                    'Aman')
                .toString()
                .toLowerCase();

        String statusLabel = "Aman";
        Color statusColor = Colors.green;
        IconData statusIcon = Icons.check_circle_rounded;

        if (rawStatus.contains('buruk') ||
            rawStatus.contains('sangat pendek') ||
            rawStatus.contains('tinggi') ||
            rawStatus.contains('tidak aman')) {
          statusLabel = "Tidak Aman";
          statusColor = Colors.redAccent;
          statusIcon = Icons.cancel_rounded;
        } else if (rawStatus.contains('kurang') ||
            rawStatus.contains('pendek') ||
            rawStatus.contains('sedang') ||
            rawStatus.contains('hati')) {
          statusLabel = "Hati-hati";
          statusColor = Colors.orange;
          statusIcon = Icons.warning_rounded;
        }

        return _buildStatusBadge(statusLabel, statusColor, statusIcon);
      },
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
