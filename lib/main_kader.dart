import 'package:flutter/material.dart';

import 'beranda_kader.dart';
import 'kader/riwayat_kader.dart';
import 'profile.dart';

class MainKader extends StatefulWidget {
  final String userId;
  final String fullName;

  const MainKader({super.key, required this.userId, required this.fullName});

  @override
  State<MainKader> createState() => _MainKader();
}

class _MainKader extends State<MainKader> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            BerandaKader(userId: widget.userId, fullName: widget.fullName),
            RiwayatKader(),
            Profile(
              userId: widget.userId,
              fullName: widget.fullName,
              role: 'kader',
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          unselectedLabelColor: Colors.black.withValues(alpha: .25),
          labelColor: Colors.blue,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: "Beranda"),
            Tab(icon: Icon(Icons.history_rounded), text: "Riwayat"),
            Tab(icon: Icon(Icons.person), text: "Profile"),
          ],
        ),
      ),
    );
  }
}
