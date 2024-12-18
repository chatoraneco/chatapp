import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String roomId; // チャットルームのID
  const ChatScreen({super.key, required this.roomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // メッセージ送信関数
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final message = _messageController.text.trim();
      final timestamp = FieldValue.serverTimestamp();

      // Firestoreの「メッセージ」サブコレクションにメッセージを保存
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'senderId': user!.uid,  // 送信者ID
        'senderName': user.displayName ?? 'Unknown User',  // Googleアカウントから名前を取得
        'content': message,  // メッセージ内容
        'timestamp': timestamp,  // タイムスタンプ
      });

      // メッセージ送信後、入力フィールドをクリア
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // メッセージ表示エリア（Firestoreからデータをリアルタイムで取得）
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp') // 時系列順に表示
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,  // 最新メッセージを下に表示
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderName = message['senderName'] ?? 'Unknown User'; // senderNameが存在しない場合は'Unknown User'
                    final content = message['content'];
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();

                    // 自分のメッセージと他人のメッセージのレイアウトを区別
                    final isMine = senderName == FirebaseAuth.instance.currentUser!.displayName;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end  // 自分のメッセージは右詰め
                            : MainAxisAlignment.start,  // 他人のメッセージは左詰め
                        children: [
                          // メッセージ内容と送信者名の表示
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: isMine ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderName,  // 送信者名
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(content),  // メッセージ内容
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 時刻の表示
                          if (timestamp != null)
                            Text(
                              "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // メッセージ送信エリア
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
