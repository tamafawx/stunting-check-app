// Menampilkan halaman utama beranda atau dashboard yang memiliki
// beberapa fitur untuk keperluan masing-masing untuk kader.

// Role yang dapat akses:
// - Kader

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stunting_posyandu/kader/edukasi_kader.dart';
import 'kader/kelola_balita_kader.dart';
import 'kader/detail_balita_kader.dart';
import 'kader/pemeriksaan_balita_kader.dart';
import 'kader/konsultasi_kader.dart';

class UserHeaderSection extends StatelessWidget {
  final String userId;
  final String fullName;

  const UserHeaderSection({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
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
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 32)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo, selamat datang',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kader Posyandu',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildNotification(),
        ],
      ),
    );
  }

  Widget _buildNotification() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_none_outlined,
          color: Colors.white,
          size: 32,
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFEB5757),
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: const Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
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
              padding: EdgeInsets.symmetric(vertical: 20),
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
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    icon: Icons.child_care_rounded,
                    color: Colors.blue,
                    title: "Total Balita",
                    value: "$totalBalita",
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade200),
                  _buildSummaryItem(
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.orange,
                    title: "Belum Diukur",
                    value: "$belumDiukurCount",
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.start,
            children: [
              _buildMenuItem(
                icon: Icons.child_care_rounded,
                color: Colors.blue,
                label: "Kelola Balita",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KelolaBalitaScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.monitor_weight_rounded,
                color: Colors.orange,
                label: "Input Pengukuran",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InputPengukuranScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.menu_book_rounded,
                color: Colors.green,
                label: "Edukasi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EdukasiKaderScreen(
                        userId: userId,
                        fullName: fullName,
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
      width: 75,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KelolaBalitaScreen(),
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
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('balita')
                .where('isHidden', isEqualTo: false)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
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
                          "Belum ada data balita",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var listBalita = snapshot.data!.docs;
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailBalitaScreen(docId: doc.id, data: data),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: jenisKelamin == 'Laki-laki'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.pink.withOpacity(0.1),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Ortu: $namaOrtu   $usia",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[400],
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
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            UserHeaderSection(userId: userId, fullName: fullName),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SummarySection(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickMenuAccess(userId: userId, fullName: fullName),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LiveToddlersSection(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
