// Jalannya utama untuk user yang mempunyai
// role orang tua.

// Role yang dapat akses:
// - Orang Tua

import 'package:flutter/material.dart';

// Import Pages (Orang Tua)
import 'beranda_orang_tua.dart';
import 'profile.dart';
import 'balita.dart';

class MainOrangTua extends StatefulWidget {
  final String userId;
  final String fullName;

  const MainOrangTua({super.key, required this.userId, required this.fullName});

  @override
  State<MainOrangTua> createState() => _MainOrangTuaState();
}

class _MainOrangTuaState extends State<MainOrangTua> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            BerandaOrangTua(fullName: widget.fullName, userId: widget.userId),
            Balita(userId: widget.userId), // Tab Anak di tengah
            Profile(
              userId: widget.userId,
              fullName: widget.fullName,
              role: 'orang-tua',
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          unselectedLabelColor: Colors.black.withValues(alpha: 0.25),
          labelColor: Colors.green,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: "Beranda"),
            Tab(icon: Icon(Icons.child_care_rounded), text: "Anak"),
            Tab(icon: Icon(Icons.person), text: "Profil"),
          ],
        ),
      ),
    );
  }
}
