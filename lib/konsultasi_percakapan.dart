import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class KonsultasiPercakapanScreen extends StatefulWidget {
  final String konsultasiId;
  final String lawanBicaraName;
  final String lawanBicaraId;
  final String currentUserId;
  final String role; // 'bidan' atau 'orang_tua'

  const KonsultasiPercakapanScreen({
    super.key,
    required this.konsultasiId,
    required this.lawanBicaraName,
    required this.lawanBicaraId,
    required this.currentUserId,
    required this.role,
  });

  @override
  State<KonsultasiPercakapanScreen> createState() => _KonsultasiPercakapanScreenState();
}

class _KonsultasiPercakapanScreenState extends State<KonsultasiPercakapanScreen> {
  final TextEditingController _msgController = TextEditingController();

  bool get isBidan => widget.role == 'bidan';
  Color get themeColor => isBidan ? Colors.purple : Colors.green;

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('konsultasi')
          .doc(widget.konsultasiId)
          .collection('messages')
          .add({
            'senderId': widget.currentUserId,
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('konsultasi')
          .doc(widget.konsultasiId)
          .update({
            'lastMessage': text,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Gagal mengirim pesan: $e");
    }
  }

  Future<void> _tutupKonsultasi() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Tutup Konsultasi", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              "Apakah Anda yakin ingin menyelesaikan dan menutup sesi konsultasi ini? Anda dan Orang Tua tidak akan bisa mengirim pesan lagi setelah ditutup.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  )
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Tutup Sesi",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('konsultasi')
            .doc(widget.konsultasiId)
            .update({'isClosed': true});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konsultasi berhasil ditutup.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menutup konsultasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat('HH:mm').format(date); // Format 24 Jam
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: widget.lawanBicaraId.isNotEmpty 
                  ? FirebaseFirestore.instance.collection('users').doc(widget.lawanBicaraId).get() 
                  : null,
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  photoUrl = userData?['profileUrl'] ?? userData?['photoUrl'] ?? userData?['profileImageUrl'];
                }

                return CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(
                          isBidan ? Icons.person_rounded : Icons.medical_services_rounded, 
                          color: Colors.white, 
                          size: 20
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lawanBicaraName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isBidan ? "Orang Tua" : "Bidan/Kader",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: themeColor,
        elevation: 2,
        shadowColor: themeColor.withValues(alpha: 0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isBidan)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('konsultasi')
                  .doc(widget.konsultasiId)
                  .snapshots(),
              builder: (context, snapshot) {
                bool isClosed = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    isClosed = data['isClosed'] == true;
                  }
                }
                if (isClosed) {
                  return const SizedBox();
                }

                return IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  tooltip: 'Tutup Konsultasi',
                  onPressed: _tutupKonsultasi,
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('konsultasi')
            .doc(widget.konsultasiId)
            .snapshots(),
        builder: (context, docSnapshot) {
          bool isClosed = false;
          if (docSnapshot.hasData && docSnapshot.data!.exists) {
            var data = docSnapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              isClosed = data['isClosed'] == true;
            }
          }

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('konsultasi')
                      .doc(widget.konsultasiId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: themeColor),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Mulai percakapan Anda...',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    var messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var data = messages[index].data() as Map<String, dynamic>;
                        bool isMe = data['senderId'] == widget.currentUserId;
                        Timestamp? timestamp = data['createdAt'];

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? themeColor : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: !isMe ? Border.all(color: Colors.grey.shade200) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 14.5,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatChatTime(timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (isClosed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Konsultasi telah diselesaikan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            maxLines: 4,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: "Ketik pesan...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
