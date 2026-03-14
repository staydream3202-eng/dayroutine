import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('DefaultFirebaseOptions are not supported.');
    }
  }

static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBIJ503jLtHD6H23tBKtpTRX5q0sZKDKH0', // 반드시 AIza...로 시작하는 이 값을 넣어야 합니다!
  authDomain: 'dayroutine-66593.firebaseapp.com',
  projectId: 'dayroutine-66593',
  storageBucket: 'dayroutine-66593.firebasestorage.app',
  messagingSenderId: '434379766095',
  appId: '1:434379766095:web:8185f84d7a8c114eceed3a',
  measurementId: 'G-MLP006JN4R',
);

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsFvBuB1H2id1PGnhfZfHYqM9BiQ0fS',
    appId: '1:434379766095:android:e107f90c611417556a9a94',
    messagingSenderId: '434379766095',
    projectId: 'dayroutine-66593',
    storageBucket: 'dayroutine-66593.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsFvBuB1H2id1PGnhfZfHYqM9BiQ0fS',
    appId: '1:434379766095:ios:ae6a3a79d389a09e6a9a94',
    messagingSenderId: '434379766095',
    projectId: 'dayroutine-66593',
    storageBucket: 'dayroutine-66593.firebasestorage.app',
    iosBundleId: 'com.example.dayroutine',
  );
}