// Menampilkan halaman notifikasi (saat ini masih pengumuman saja).

// Role yang dapat akses:
// - Admin
// - Kader
// - Bidan
// - Orang Tua

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Notifikasi extends StatelessWidget {
  final String userId;
  final String role;

  const Notifikasi({super.key, required this.userId, required this.role});

  Color _getMainThemeColor(String currentRole) {
    String role = currentRole.toLowerCase();
    return (role == 'admin')
        ? Colors.red
        : (role == 'kader')
        ? Colors.blue
        : (role == 'bidan')
        ? Colors.purple
        : (role == 'orang-tua')
        ? Colors.green
        : Colors.grey;
  }

  LinearGradient _getRoleGradient(String currentRole) {
    String role = currentRole.toLowerCase();
    return (role == 'admin')
        ? const LinearGradient(
            colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (role == 'kader')
        ? const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (role == 'bidan')
        ? const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (role == 'orang-tua')
        ? const LinearGradient(
            colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Colors.grey, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  Future<void> _markAsRead(String docId, List readBy) async {
    if (!readBy.contains(userId)) {
      await FirebaseFirestore.instance
          .collection('pengumuman')
          .doc(docId)
          .update({
            'readBy': FieldValue.arrayUnion([userId]),
          });
    }
  }

  void _showNotificationDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    List readBy,
  ) {
    _markAsRead(docId, readBy);

    Color themeColor = _getMainThemeColor(role);
    String judul = data['judul'] ?? 'Pengumuman';
    String konten = data['konten'] ?? 'Tidak ada detail.';
    String penulis = data['penulis'] ?? 'Admin Posyandu';
    Timestamp? createdAt = data['createdAt'];
    String tanggal = '-';

    if (createdAt != null) {
      tanggal = DateFormat('dd MMMM yyyy, HH:mm').format(createdAt.toDate());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: themeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tanggal,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      konten,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[500], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Diposting oleh: $penulis",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _getMainThemeColor(role);
    LinearGradient bgGradient = _getRoleGradient(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: bgGradient),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pengumuman')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_rounded,
                      size: 64,
                      color: themeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Belum Ada Notifikasi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Anda akan melihat pembaruan dan\npengumuman di sini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var document = docs[index];
              var data = document.data() as Map<String, dynamic>;
              String docId = document.id;

              String judul = data['judul'] ?? 'Pengumuman Baru';
              String konten = data['konten'] ?? '';
              Timestamp? createdAt = data['createdAt'];
              List<dynamic> readBy = data['readBy'] ?? [];
              bool isRead = readBy.contains(userId);

              String tanggal = '-';
              if (createdAt != null) {
                tanggal = DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(createdAt.toDate());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.white
                      : themeColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead
                        ? Colors.grey.shade200
                        : themeColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    if (!isRead)
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    if (isRead)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        _showNotificationDetail(context, data, docId, readBy),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.grey.shade100
                                  : themeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRead
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_active_rounded,
                              color: isRead ? Colors.grey.shade500 : themeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        judul,
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 15,
                                          color: isRead
                                              ? Colors.black87
                                              : themeColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  konten,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tanggal,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
