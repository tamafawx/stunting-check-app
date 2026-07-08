import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailEdukasiBidan extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailEdukasiBidan({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String judul = data['judul'] ?? 'Tanpa Judul';
    String konten = data['konten'] ?? '';
    String imageUrl = data['imageUrl'] ?? '';
    String namaPenulis = data['namaPenulis'] ?? 'Kader';
    String fotoPenulis = data['fotoPenulis'] ?? '';
    String rolePenulis = data['rolePenulis'] ?? 'Kader Posyandu';

    Timestamp? createdAt = data['createdAt'];
    String tanggal = '-';
    if (createdAt != null) {
      DateTime dt = createdAt.toDate();
      List<String> bulan = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "Mei",
        "Jun",
        "Jul",
        "Ags",
        "Sep",
        "Okt",
        "Nov",
        "Des",
      ];
      tanggal = "${dt.day} ${bulan[dt.month - 1]} ${dt.year}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar dibuat transparan (akan ditimpa oleh gambar)
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.purple[100],
                child: Icon(
                  Icons.menu_book,
                  size: 80,
                  color: Colors.purple[300],
                ),
              ),

            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          backgroundImage: fotoPenulis.isNotEmpty
                              ? NetworkImage(fotoPenulis)
                              : null,
                          child: fotoPenulis.isEmpty
                              ? const Icon(Icons.person, color: Colors.purple)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaPenulis, // Identitas pembuat (Bambang) tampil di sini
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                rolePenulis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Diterbitkan",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text(
                              tanggal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    konten,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
