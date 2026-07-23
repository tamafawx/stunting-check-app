// Ini adalah tampilan halaman profile yang di mana user dapat
// melihat informasi user dan melakukan navigasi. Di sini juga
// terdapat navigasi sederhana.

// Role yang dapat akses:
// - Kader
// - Bidan
// - Orang Tua

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../login.dart';
import 'ubah_profile.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String role;
  final String profileUrl;
  final Color headerColor;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.email,
    required this.role,
    required this.profileUrl,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    String displayRole = (role == 'kader')
        ? 'Kader Posyandu'
        : (role == 'bidan')
        ? 'Bidan Posyandu'
        : (role == 'orang-tua')
        ? 'Orang Tua'
        : "Null";

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 30),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFE3F2FD),
                  backgroundImage: profileUrl.isNotEmpty
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl.isEmpty
                      ? Icon(Icons.person, size: 46, color: headerColor)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  displayRole,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class Profile extends StatelessWidget {
  final String userId;
  final String fullName;
  final String role;

  const Profile({
    super.key,
    required this.userId,
    required this.fullName,
    required this.role,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                "Keluar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color mainThemeColor = (role == 'kader')
        ? Colors.blue
        : (role == 'bidan')
        ? Colors.purple
        : (role == 'orang-tua')
        ? Colors.green
        : Colors.grey;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String displayRole = role;
        String displayEmail = "Memuat data...";
        String displayName = fullName;
        String profileUrl = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          displayRole = (data['role'] ?? '').toString().toLowerCase();
          displayEmail = data['email'] ?? 'Tidak ada email';
          displayName = data['fullName'] ?? fullName;
          profileUrl = data['profileUrl'] ?? '';
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Profil Akun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: mainThemeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  fullName: displayName,
                  email: displayEmail,
                  role: displayRole,
                  profileUrl: profileUrl,
                  headerColor: mainThemeColor,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PENGATURAN AKUN",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              icon: Icons.person_outline_rounded,
                              title: "Ubah Data Akun",
                              iconColor: const Color(0xFF1E88E5),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UbahProfile(userId: userId, role: role),
                                  ),
                                );
                              },
                            ),
                            const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFF1F5F9),
                            ),
                            _buildMenuRow(
                              icon: Icons.help_outline_rounded,
                              title: "Pusat Bantuan",
                              iconColor: Colors.teal,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "TINDAKAN",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                        child: _buildMenuRow(
                          icon: Icons.logout_rounded,
                          title: "Keluar",
                          iconColor: Colors.redAccent,
                          isDestructive: true,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ),
                      const SizedBox(height: 48),

                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Versi 1.0.0",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "UID: $userId",
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 10,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.redAccent
                        : const Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
