import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';

void main() {
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
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      ),
      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends StatefulWidget {
  const _RootScreen();
  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  bool _showLanding = true;

  @override
  Widget build(BuildContext context) {
    if (_showLanding) {
      return LandingScreen(onStart: () => setState(() => _showLanding = false));
    }
    return HomeScreen(onGoLanding: () => setState(() => _showLanding = true));
  }
}
