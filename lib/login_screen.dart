import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_list_screen.dart'; // チャットルーム一覧画面のインポート

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<User?> signInWithGoogle() async {
    try {
      // Google認証プロセス
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Googleサインインがキャンセルされました。');
        return null; // ユーザーがキャンセルした場合
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebaseに認証情報を送信
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // ユーザー情報をFirestoreに保存
      await saveUserToFirestore(userCredential.user);

      return userCredential.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> saveUserToFirestore(User? user) async {
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Firestoreにすでにユーザーが存在するか確認
      final userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        // 既存ユーザーの場合、`lastSignIn`を更新
        await userRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        print('既存ユーザーとしてログイン: ${user.email}');
      } else {
        // 新規ユーザーの場合、すべてのデータを保存
        final userData = {
          'email': user.email,
          'name': user.displayName,
          'photoURL': user.photoURL,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
        };
        await userRef.set(userData);
        print('新規ユーザーが登録されました: ${user.email}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Chat Login"),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Googleでログイン"),
          onPressed: () async {
            User? user = await signInWithGoogle();
            if (user != null) {
              final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
              final userSnapshot = await userRef.get();

              // 新規登録か既存ユーザーかを区別
              if (userSnapshot.exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ようこそ、${user.displayName}さん！')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('新規登録が完了しました！ようこそ、${user.displayName}さん！')),
                );
              }

              // チャットルーム一覧画面に遷移
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatRoomListScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Googleログインに失敗しました。')),
              );
            }
          },
        ),
      ),
    );
  }
}
