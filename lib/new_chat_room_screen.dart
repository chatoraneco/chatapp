import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_room_list_screen.dart'; // チャットルーム一覧画面のインポート

class NewChatRoomScreen extends StatefulWidget {
  @override
  _NewChatRoomScreenState createState() => _NewChatRoomScreenState();
}

class _NewChatRoomScreenState extends State<NewChatRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _participants = []; // 追加された参加者リスト
  List<Map<String, dynamic>> _searchResults = []; // 検索結果のリスト

  String _roomName = '';

  @override
  void dispose() {
    _roomNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createRoom() async {
    if (_roomName.isNotEmpty && _participants.isNotEmpty) {
      // Firestoreに新しいチャットルームを保存
      try {
        // 新しいルーム情報をFirestoreのchatRoomsコレクションに保存
        DocumentReference roomRef = await FirebaseFirestore.instance
            .collection('chatRooms')
            .add({
          'name': _roomName,  // ルーム名
          'participants': _participants,  // 参加者リスト（UID）
          'lastMessage': '',  // 最初はメッセージなし
          'updatedAt': FieldValue.serverTimestamp(),  // 作成日時
        });

        // 成功したら、ルーム作成画面を閉じてチャットルーム一覧画面に遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomListScreen()),
        );
      } catch (e) {
        // エラーハンドリング
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ルーム作成に失敗しました")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ルーム名と参加者を入力してください")),
      );
    }
  }

  // ユーザー検索の関数
  void _searchUsers() async {
    String searchTerm = _searchController.text;
    if (searchTerm.isNotEmpty) {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'],
                })
            .toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  // 参加者追加の関数
  void _addParticipant(String userId) {
    setState(() {
      _participants.add(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新規チャットルーム作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ルーム名入力フィールド
            TextField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'ルーム名',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _roomName = value;
                });
              },
            ),
            SizedBox(height: 20),
            // 参加者検索フィールド
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '参加者を検索',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
            ),
            SizedBox(height: 20),
            // 検索結果リスト
            _searchResults.isEmpty
                ? Container()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var user = _searchResults[index];
                      return ListTile(
                        title: Text(user['name']),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addParticipant(user['id']),
                        ),
                      );
                    },
                  ),
            SizedBox(height: 20),
            // 追加された参加者リスト
            Text('追加された参加者:'),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_participants[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        _participants.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // ルーム作成ボタン
            ElevatedButton(
              onPressed: _createRoom,
              child: Text('ルーム作成'),
            ),
          ],
        ),
      ),
    );
  }
}
