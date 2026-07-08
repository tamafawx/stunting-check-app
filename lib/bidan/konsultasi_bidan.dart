import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'percakapan_konsultasi_bidan.dart';

class KonsultasiBidan extends StatefulWidget {
  final String userId;
  final String fullName;

  const KonsultasiBidan({
    super.key,
    required this.userId,
    required this.fullName,
  });

  @override
  State<KonsultasiBidan> createState() => _KonsultasiBidanState();
}

class _KonsultasiBidanState extends State<KonsultasiBidan> {
  String _searchQuery = '';
  bool _isAscending = false; // Default: Terbaru di atas
  final TextEditingController _searchController = TextEditingController();

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
                  : Icons.speaker_notes_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSelesai
                  ? "Belum ada riwayat konsultasi."
                  : "Belum ada konsultasi aktif.",
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var doc = docs[index];
        var data = doc.data() as Map<String, dynamic>;

        String judul = data['judul'] ?? 'Tanpa Judul';
        String orangTuaName = data['orangTuaName'] ?? 'Orang Tua';
        String lastMessage = data['lastMessage'] ?? '';
        Timestamp? lastMessageTime = data['lastMessageTime'];
        bool isClosed = data['isClosed'] == true;

        return Card(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatKonsultasiBidan(
                    konsultasiId: doc.id,
                    lawanBicaraName: orangTuaName,
                    currentUserId: widget.userId,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              child: Icon(
                isClosed ? Icons.lock_rounded : Icons.person_rounded,
                color: isClosed ? Colors.grey : Colors.purple,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(lastMessageTime),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Ortu: $orangTuaName",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.purple[50],
        appBar: AppBar(
          title: const Text(
            "Konsultasi",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Aktif"),
              Tab(text: "Selesai"),
            ],
          ),
        ),
        body: Column(
          children: [
            // BAGIAN FILTER (MIRIPI ADMIN)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari judul/nama orang tua...',
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _isAscending = !_isAscending),
                      icon: Icon(
                        _isAscending
                            ? Icons.sort_by_alpha
                            : Icons.access_time_filled_rounded,
                        color: Colors.purple,
                      ),
                      label: Text(
                        _isAscending ? 'A-Z' : 'Terbaru',
                        style: const TextStyle(color: Colors.purple),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // STREAM BUILDER
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('konsultasi')
                    .where('kaderId', isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  var allDocs = snapshot.data?.docs ?? [];

                  // Filter & Search
                  var filteredDocs = allDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String judul = (data['judul'] ?? '')
                        .toString()
                        .toLowerCase();
                    String ortu = (data['orangTuaName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return judul.contains(_searchQuery.toLowerCase()) ||
                        ortu.contains(_searchQuery.toLowerCase());
                  }).toList();

                  // Sorting
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
      ),
    );
  }
}
