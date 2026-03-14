import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// 클래스 이름이 정확히 AuthService여야 합니다.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ★ 이 줄이 없으면 main.dart에서 무조건 에러가 납니다.
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        return await _auth.signInWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ));
      }
    } catch (e) {
      debugPrint("로그인 에러: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}