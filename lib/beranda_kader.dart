// Menampilkan halaman utama beranda atau dashboard yang memiliki
// beberapa fitur untuk keperluan masing-masing untuk kader.

// Role yang dapat akses:
// - Kader

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edukasi.dart';
import 'balita_kelola.dart';
import 'balita_detail.dart';
import 'pemeriksaan_balita.dart';
import 'kader/konsultasi_kader.dart';
import 'notifikasi.dart';

class UserHeaderSection extends StatelessWidget {
  final String userId;
  final String fullName;

  const UserHeaderSection({
    super.key,
    required this.userId,
    required this.fullName,
  });

  Widget _buildNotification(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Notifikasi(userId: userId, role: 'kader'),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pengumuman')
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  List<dynamic> readBy = data['readBy'] ?? [];
                  if (!readBy.contains(userId)) {
                    unreadCount++;
                  }
                }
              }
              if (unreadCount == 0) return const SizedBox();

              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade700, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)], // Gradien Biru Kader
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x401976D2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              String? profileUrl;
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                profileUrl = data['profileUrl'];
              }

              return Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blueAccent.shade100,
                  backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl == null || profileUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 36)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Kader Posyandu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildNotification(context),
        ],
      ),
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime startOfMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('balita')
          .where('isHidden', isEqualTo: false)
          .snapshots(),
      builder: (context, balitaSnapshot) {
        if (balitaSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }

        int totalBalita = balitaSnapshot.hasData
            ? balitaSnapshot.data!.docs.length
            : 0;

        List<String> activeBalitaIds = balitaSnapshot.hasData
            ? balitaSnapshot.data!.docs.map((doc) => doc.id).toList()
            : [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pemeriksaan')
              .where(
                'tanggal',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .snapshots(),
          builder: (context, pemeriksaanSnapshot) {
            int belumDiukurCount = totalBalita;
            if (pemeriksaanSnapshot.hasData && balitaSnapshot.hasData) {
              Set<String> measuredBalitaIds = pemeriksaanSnapshot.data!.docs
                  .map(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['balitaId']
                            ?.toString() ??
                        '',
                  )
                  .toSet();

              belumDiukurCount = activeBalitaIds
                  .where((id) => !measuredBalitaIds.contains(id))
                  .length;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.15),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.child_care_rounded,
                      size: 120,
                      color: Colors.blue.withValues(alpha: 0.05),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryMetric(
                          icon: Icons.groups_rounded,
                          label: "Total Balita",
                          value: "$totalBalita",
                          color: Colors.blue,
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                        _buildSummaryMetric(
                          icon: Icons.monitor_weight_outlined,
                          label: "Belum Diukur",
                          value: "$belumDiukurCount",
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Anak",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class QuickMenuAccess extends StatelessWidget {
  final String userId;
  final String fullName;

  const QuickMenuAccess({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Quick Access (Menu Cepat)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16.0,
            runSpacing: 24.0,
            alignment: WrapAlignment.start,
            children: [
              _buildMenuItem(
                icon: Icons.child_care_rounded,
                color: Colors.blue,
                label: "Kelola\nBalita",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KelolaBalita(role: 'kader'),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.monitor_weight_rounded,
                color: Colors.orange,
                label: "Input\nPengukuran",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InputPengukuran(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.menu_book_rounded,
                color: Colors.green,
                label: "Pojok\nEdukasi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Edukasi(
                        userId: userId,
                        fullName: fullName,
                        role: 'kader',
                      ),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.chat_bubble_rounded,
                color: Colors.redAccent,
                label: "Konsultasi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KonsultasiKaderScreen(
                        userId: userId,
                        fullName: fullName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class LiveToddlersSection extends StatelessWidget {
  const LiveToddlersSection({super.key});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daftar Balita Aktif",
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
                      builder: (context) => const KelolaBalita(role: 'kader'),
                    ),
                  );
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('balita')
                .where('isHidden', isEqualTo: false)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Belum ada data balita.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              var listBalita = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listBalita.length,
                itemBuilder: (context, index) {
                  var doc = listBalita[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = data['nama'] ?? 'Tanpa Nama';
                  String jenisKelamin = data['jenisKelamin'] ?? 'Laki-laki';
                  String usia = _calculateAge(data['tanggalLahir']);
                  String namaOrtu = data['namaOrangTua'] ?? '-';
                  String? fotoUrl = data['fotoUrl'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailBalita(
                              docId: doc.id,
                              data: data,
                              role: 'kader',
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: jenisKelamin == 'Laki-laki'
                            ? Colors.blue.withValues(alpha: 0.15)
                            : Colors.pink.withValues(alpha: 0.15),
                        backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: (fotoUrl == null || fotoUrl.isEmpty)
                            ? Icon(
                                Icons.child_care,
                                size: 20,
                                color: jenisKelamin == 'Laki-laki'
                                    ? Colors.blue
                                    : Colors.pink,
                              )
                            : null,
                      ),
                      title: Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Ortu: $namaOrtu",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Usia: $usia",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class BerandaKader extends StatelessWidget {
  final String userId;
  final String fullName;

  const BerandaKader({super.key, required this.userId, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserHeaderSection(userId: userId, fullName: fullName),
            const SummarySection(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: QuickMenuAccess(userId: userId, fullName: fullName),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LiveToddlersSection(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
