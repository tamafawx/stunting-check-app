import 'package:flutter/material.dart';
import 'beranda_bidan.dart';
import 'riwayat_bidan.dart';
import 'profile_bidan.dart';

class MainBidan extends StatefulWidget {
  final String userId;
  final String fullName;

  const MainBidan({super.key, required this.userId, required this.fullName});

  @override
  State<MainBidan> createState() => _MainBidanState();
}

class _MainBidanState extends State<MainBidan> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            BerandaBidan(userId: widget.userId, fullName: widget.fullName),
            const RiwayatBidan(),
            ProfilBidan(userId: widget.userId, fullName: widget.fullName),
          ],
        ),
        bottomNavigationBar: TabBar(
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          unselectedLabelColor: Colors.black.withOpacity(0.25),
          labelColor: Colors.purple,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: "Beranda"),
            Tab(icon: Icon(Icons.history_rounded), text: "Riwayat"),
            Tab(icon: Icon(Icons.person), text: "Profil"),
          ],
        ),
      ),
    );
  }
}
