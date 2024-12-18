import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_chat_room_screen.dart'; // 新規チャットルーム作成画面のインポート
import 'login_screen.dart'; // ログイン画面のインポート
import 'chat_screen.dart'; // チャット画面のインポート（新しく追加したChatScreen）

class ChatRoomListScreen extends StatelessWidget {
  const ChatRoomListScreen({super.key});

  // チャットルームを削除する関数
  void _deleteChatRoom(BuildContext context, String roomId) async {
    // チャットルームを削除する
    try {
      await FirebaseFirestore.instance.collection('chatRooms').doc(roomId).delete();
      
      // ウィジェットがまだツリーに存在するか確認してから SnackBar を表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('チャットルームが削除されました')),
        );
      }
    } catch (e) {
      // エラー処理
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 左上の戻るボタン
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // 戻るアイコン
          onPressed: () {
            // ログイン画面に遷移
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: const Text("チャットルーム一覧"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 新規チャットルーム作成画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewChatRoomScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }

          final chatRooms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(chatRooms[index]['name']),  // ルーム名
                subtitle: Text('最終メッセージ: ${chatRooms[index]['lastMessage'] ?? 'なし'}'),  // 最終メッセージ
                onTap: () {
                  // チャットルーム詳細画面に遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        roomId: chatRooms[index].id, // ルームIDを渡す
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // 削除確認ダイアログを表示
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('チャットルームを削除しますか?'),
                          content: const Text('この操作は取り消せません。'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () {
                                // チャットルームを削除する関数を呼び出す
                                _deleteChatRoom(context, chatRooms[index].id);
                                Navigator.of(context).pop();
                              },
                              child: const Text('削除'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
