import 'package:flutter/material.dart';

import '../beranda_admin.dart';

import '../login.dart';

class MainAdmin extends StatefulWidget {
  final String userId;
  final String fullName;

  const MainAdmin({super.key, required this.userId, required this.fullName});

  @override
  State<MainAdmin> createState() => _MainAdmin();
}

class _MainAdmin extends State<MainAdmin> {
  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Konfirmasi Logout?"),
          content: const Text("Apakah anda yakin ingin keluar?"),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Tidak"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black.withValues(alpha: 0.75),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _logoutDialog,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        hoverColor: Colors.red,
        child: const Icon(Icons.logout),
      ),
      body: BerandaAdmin(userId: widget.userId, fullName: widget.fullName),
    );
  }
}
