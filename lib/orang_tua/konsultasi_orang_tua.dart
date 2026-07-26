import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tambah_konsultasi_orang_tua.dart';
import 'percakapan_konsultasi_orang_tua.dart';

class KonsultasiOrangTuaScreen extends StatelessWidget {
  final String userId;
  final String fullName;

  const KonsultasiOrangTuaScreen({
    super.key,
    required this.userId,
    required this.fullName,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text(
          "Konsultasi Saya",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('konsultasi')
            .where('orangTuaId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Terjadi kesalahan sistem: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada konsultasi.",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tekan tombol + untuk mulai berkonsultasi",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          var listKonsultasi = snapshot.data!.docs.toList();
          listKonsultasi.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;

            Timestamp? timeA = dataA['lastMessageTime'];
            Timestamp? timeB = dataB['lastMessageTime'];

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) {
              return 1;
            }
            if (timeB == null) return -1;

            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listKonsultasi.length,
            itemBuilder: (context, index) {
              var doc = listKonsultasi[index];
              var data = doc.data() as Map<String, dynamic>;

              String judul = data['judul'] ?? 'Tanpa Judul';
              String kaderName = data['kaderName'] ?? 'Kader';
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
                        builder: (context) => ChatKonsultasiScreen(
                          konsultasiId: doc.id,
                          lawanBicaraName: kaderName,
                          currentUserId: userId,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: Icon(
                      isClosed
                          ? Icons.lock_rounded
                          : Icons.support_agent_rounded,
                      color: isClosed ? Colors.grey : Colors.green,
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
                        "Kader: $kaderName",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
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
                  trailing: isClosed
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Selesai",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MulaiKonsultasiOrangTuaScreen(
                userId: userId,
                fullName: fullName,
              ),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text("Konsultasi Baru"),
      ),
    );
  }
}
