import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stunting_posyandu/orang_tua/konsultasi_orang_tua.dart';
import 'orang_tua/edukasi_orang_tua.dart';
import 'orang_tua/detail_edukasi_orang_tua.dart';
import 'orang_tua/balita_orang_tua.dart';
import 'orang_tua/jadwal_orang_tua.dart'; // Import Jadwal

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
        color: Colors.green,
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
                  backgroundColor: Colors.greenAccent,
                  backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl == null || profileUrl.isEmpty
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$fullName 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orang Tua Balita',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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
              '1',
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
  final String userId;
  const SummarySection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('balita')
          .where('orangTuaIds', arrayContains: userId)
          .where('isHidden', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }
        int totalAnak = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
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
                color: Colors.green,
                title: "Anak Terdaftar",
                value: "$totalAnak",
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade200),
              _buildSummaryItem(
                icon: Icons.menu_book_rounded,
                color: Colors.purple,
                title: "Edukasi Gizi",
                value: "Cek",
              ),
            ],
          ),
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
            color: color.withOpacity(0.1),
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
            color: Colors.grey.withOpacity(0.05),
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
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuItem(
                  icon: Icons.child_care_rounded,
                  color: Colors.green,
                  label: "Data Balita",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BalitaOrangTuaScreen(userId: userId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildMenuItem(
                  icon: Icons.calendar_month_rounded,
                  color: Colors.orange,
                  label: "Jadwal",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JadwalOrangTuaScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildMenuItem(
                  icon: Icons.menu_book_rounded,
                  color: Colors.purple,
                  label: "Edukasi\nGizi",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EdukasiOrangTuaScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildMenuItem(
                  icon: Icons.chat_bubble_rounded,
                  color: Colors.redAccent,
                  label: "Konsultasi",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KonsultasiOrangTuaScreen(
                          userId: userId,
                          fullName: fullName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
                  color: color.withOpacity(0.1),
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

class DaftarAnakSection extends StatelessWidget {
  final String userId;
  const DaftarAnakSection({super.key, required this.userId});

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
            color: Colors.grey.withOpacity(0.05),
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
                "Anak Saya",
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
                      builder: (context) =>
                          BalitaOrangTuaScreen(userId: userId),
                    ),
                  );
                },
                child: const Text(
                  "Lihat Detail",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('balita')
                .where('orangTuaIds', arrayContains: userId)
                .where('isHidden', isEqualTo: false)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
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
                          "Belum ada data anak yang terhubung",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var listBalita = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listBalita.length,
                itemBuilder: (context, index) {
                  var doc = listBalita[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = data['nama'] ?? 'Tanpa Nama';
                  String jenisKelamin = data['jenisKelamin'] ?? 'Laki-laki';
                  String usia = _calculateAge(data['tanggalLahir']);
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
                                BalitaOrangTuaScreen(userId: userId),
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
                        "Usia: $usia",
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

class JadwalMendatangSection extends StatelessWidget {
  const JadwalMendatangSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil awal hari ini (jam 00:00:00) agar jadwal hari ini tetap muncul
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                "Jadwal Mendatang",
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
                      builder: (context) => const JadwalOrangTuaScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jadwal')
                .where(
                  'tanggal',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
                )
                .orderBy('tanggal')
                .limit(2) // Menampilkan maksimal 2 jadwal terdekat
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Tidak ada jadwal dalam waktu dekat.",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                );
              }

              var listJadwal = snapshot.data!.docs;
              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listJadwal.length,
                itemBuilder: (context, index) {
                  var data = listJadwal[index].data() as Map<String, dynamic>;
                  String judul = data['judul'] ?? 'Tanpa Judul';
                  String kategori = data['kategori'] ?? 'Posyandu';
                  String lokasi = data['lokasi'] ?? '-';
                  Timestamp? tanggalTs = data['tanggal'];
                  DateTime tanggal = tanggalTs?.toDate() ?? DateTime.now();

                  String formattedDate = DateFormat(
                    'dd MMM yyyy',
                  ).format(tanggal);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            kategori == 'Posyandu'
                                ? Icons.group_rounded
                                : Icons.vaccines_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      lokasi,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}

class ArtikelTerbaruSection extends StatelessWidget {
  const ArtikelTerbaruSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                "Artikel Terbaru",
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
                      builder: (context) => const EdukasiOrangTuaScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('edukasi')
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Belum ada artikel edukasi.",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                );
              }

              var listArtikel = snapshot.data!.docs;
              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listArtikel.length,
                itemBuilder: (context, index) {
                  var doc = listArtikel[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String judul = data['judul'] ?? 'Tanpa Judul';
                  String imageUrl = data['imageUrl'] ?? '';
                  Timestamp? createdAt = data['createdAt'];
                  String tanggal = '-';

                  if (createdAt != null) {
                    DateTime dt = createdAt.toDate();
                    tanggal = "${dt.day}/${dt.month}/${dt.year}";
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailEdukasiOrangTuaScreen(data: data),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                        ],
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

class BerandaOrangTua extends StatelessWidget {
  final String userId;
  final String fullName;

  const BerandaOrangTua({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            UserHeaderSection(userId: userId, fullName: fullName),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SummarySection(userId: userId),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickMenuAccess(userId: userId, fullName: fullName),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DaftarAnakSection(userId: userId),
            ),
            const SizedBox(height: 16),
            // Penambahan Widget Jadwal Mendatang
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: JadwalMendatangSection(),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ArtikelTerbaruSection(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
