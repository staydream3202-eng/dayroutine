import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DayRoutineApp());
}

class DayRoutineApp extends StatelessWidget {
  const DayRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '데이루틴',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
        ),
        useMaterial3: true,
      ),
      // StreamBuilder를 통해 로그인 상태에 따라 화면을 분기합니다.
      home: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          // 로딩 중일 때 표시할 화면
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            );
          }
          // 로그인 데이터가 있으면 홈 화면으로 이동
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }
          // 데이터가 없으면 로그인 화면으로 이동
          return const LoginScreen();
        },
      ),
    );
  }
}