import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'konsultasi_percakapan.dart';
import 'konsultasi_baru.dart';

class KonsultasiBerandaPercakapan extends StatefulWidget {
  final String userId;
  final String fullName;
  final String role;

  const KonsultasiBerandaPercakapan({
    super.key,
    required this.userId,
    required this.fullName,
    required this.role,
  });

  @override
  State<KonsultasiBerandaPercakapan> createState() =>
      _KonsultasiBerandaPercakapanState();
}

class _KonsultasiBerandaPercakapanState
    extends State<KonsultasiBerandaPercakapan> {
  String _searchQuery = '';
  bool _isAscending = false;
  final TextEditingController _searchController = TextEditingController();

  bool get isBidan => widget.role == 'bidan';
  Color get themeColor => isBidan ? Colors.purple : Colors.green;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildKonsultasiList(
    List<QueryDocumentSnapshot> docs,
    bool isSelesai,
    BuildContext context,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelesai
                  ? Icons.history_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isSelesai
                  ? "Belum ada riwayat konsultasi."
                  : "Belum ada konsultasi aktif.",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isBidan && !isSelesai) ...[
              const SizedBox(height: 8),
              Text(
                "Tekan tombol + untuk mulai berkonsultasi",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;

        String judul = data['judul'] ?? 'Tanpa Judul';
        String lastMessage = data['lastMessage'] ?? '';
        Timestamp? lastMessageTime = data['lastMessageTime'];
        bool isClosed = data['isClosed'] == true;

        String lawanBicaraId = isBidan
            ? (data['orangTuaId'] ?? '')
            : (data['kaderId'] ?? '');
        String lawanBicaraName = isBidan
            ? (data['orangTuaName'] ?? 'Orang Tua')
            : (data['kaderName'] ?? 'Bidan');
        String lawanRoleLabel = isBidan ? 'Orang Tua' : 'Bidan';

        return Card(
          elevation: 2,
          shadowColor: themeColor.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KonsultasiPercakapanScreen(
                    konsultasiId: doc.id,
                    lawanBicaraName: lawanBicaraName,
                    lawanBicaraId: lawanBicaraId,
                    currentUserId: widget.userId,
                    role: widget.role,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: lawanBicaraId.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(lawanBicaraId)
                              .get()
                        : null,
                    builder: (context, snapshot) {
                      String? photoUrl;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        photoUrl =
                            userData?['profileUrl'] ??
                            userData?['photoUrl'] ??
                            userData?['profileImageUrl'];
                      }

                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: themeColor.withValues(alpha: 0.15),
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(
                                    isBidan
                                        ? Icons.person_rounded
                                        : Icons.medical_services_rounded,
                                    color: themeColor,
                                    size: 30,
                                  )
                                : null,
                          ),
                          if (isClosed)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                judul,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "$lawanRoleLabel: $lawanBicaraName",
                            style: TextStyle(
                              fontSize: 11,
                              color: themeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lastMessage.isEmpty
                              ? "Belum ada pesan."
                              : lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String queryField = isBidan ? 'kaderId' : 'orangTuaId';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Konsultasi Saya",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Aktif"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Selesai"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText:
                          'Cari judul/nama ${isBidan ? "orang tua" : "kader"}...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daftar Percakapan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _isAscending = !_isAscending),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isAscending
                                    ? Icons.sort_by_alpha
                                    : Icons.access_time_filled_rounded,
                                color: themeColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAscending ? 'A-Z' : 'Terbaru',
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('konsultasi')
                    .where(queryField, isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: themeColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Terjadi kesalahan: ${snapshot.error}"),
                    );
                  }

                  var allDocs = snapshot.data?.docs ?? [];

                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String judul = (data['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    String namaBidan = (data['kaderName'] ?? '')
                        .toString()
                        .toLowerCase();
                    String namaOrtu = (data['orangTuaName'] ?? '')
                        .toString()
                        .toLowerCase();
                    String q = _searchQuery.toLowerCase();

                    if (isBidan) {
                      return judul.contains(q) || namaOrtu.contains(q);
                    } else {
                      return judul.contains(q) || namaBidan.contains(q);
                    }
                  }).toList();

                  filteredDocs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    if (_isAscending) {
                      return (dataA['judul'] ?? '').toString().compareTo(
                        dataB['judul'] ?? '',
                      );
                    } else {
                      Timestamp? timeA = dataA['lastMessageTime'];
                      Timestamp? timeB = dataB['lastMessageTime'];
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;
                      return timeB.compareTo(timeA);
                    }
                  });

                  return TabBarView(
                    children: [
                      _buildKonsultasiList(
                        filteredDocs
                            .where(
                              (doc) => (doc.data() as Map)['isClosed'] != true,
                            )
                            .toList(),
                        false,
                        context,
                      ),
                      _buildKonsultasiList(
                        filteredDocs
                            .where(
                              (doc) => (doc.data() as Map)['isClosed'] == true,
                            )
                            .toList(),
                        true,
                        context,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: !isBidan
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KonsultasiBaru(
                        userId: widget.userId,
                        fullName: widget.fullName,
                      ),
                    ),
                  );
                },
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_comment_rounded),
                label: const Text(
                  "Konsultasi Baru",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                elevation: 4,
              )
            : null,
      ),
    );
  }
}
