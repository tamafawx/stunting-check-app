import 'package:flutter/material.dart';

import '../beranda_kader.dart';
import 'riwayat_kader.dart';
import 'profile_kader.dart';

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
            ProfileKader(userId: widget.userId, fullName: widget.fullName),
          ],
        ),
        bottomNavigationBar: TabBar(
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          unselectedLabelColor: Colors.black.withOpacity(0.25),
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
