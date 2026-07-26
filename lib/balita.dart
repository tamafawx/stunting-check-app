import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'balita_detail.dart';

class Balita extends StatefulWidget {
  final String userId;

  const Balita({super.key, required this.userId});

  @override
  State<Balita> createState() => _BalitaState();
}

class _BalitaState extends State<Balita> {
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
        backgroundColor: const Color(0xFF5CB85C),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
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
                    latestStatusMap[bId] =
                        data['statusStunting'] ?? 'Belum Diukur';
                  }
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: balitaDocs.length,
                itemBuilder: (context, index) {
                  final document = balitaDocs[index];
                  final data = document.data() as Map<String, dynamic>;
                  final docId = document.id;

                  final nama = data['nama'] ?? 'Tanpa Nama';
                  final jenisKelamin = data['jenisKelamin'] ?? '-';
                  final usia = _calculateAge(data['tanggalLahir']);
                  final String? fotoUrl = data['fotoUrl'];

                  String statusRaw = latestStatusMap[docId] ?? 'Belum Diukur';
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
                  IconData jkIcon = jenisKelamin == 'Laki-laki'
                      ? Icons.male
                      : Icons.female;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailBalita(
                            docId: docId,
                            data: data,
                            role: 'orang-tua',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
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
                                  backgroundColor: jkColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage:
                                      fotoUrl != null && fotoUrl.isNotEmpty
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
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.cake,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
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
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF0F0F0),
                            ),
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
                                    color: statusTextColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusTextColor,
                                    ),
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
                },
              );
            },
          );
        },
      ),
    );
  }
}
