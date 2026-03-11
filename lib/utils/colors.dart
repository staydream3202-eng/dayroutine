import 'package:flutter/material.dart';

class RoutineColor {
  final Color bg;
  final Color light;
  final Color text;
  final String name;

  const RoutineColor({
    required this.bg,
    required this.light,
    required this.text,
    required this.name,
  });
}

const List<RoutineColor> routineColors = [
  RoutineColor(bg: Color(0xFFFF6B6B), light: Color(0xFFFFE5E5), text: Color(0xFFC0392B), name: '토마토'),
  RoutineColor(bg: Color(0xFF4ECDC4), light: Color(0xFFE0F8F7), text: Color(0xFF1A8F88), name: '민트'),
  RoutineColor(bg: Color(0xFFFFD93D), light: Color(0xFFFFF8DC), text: Color(0xFFB8860B), name: '선샤인'),
  RoutineColor(bg: Color(0xFF6BCB77), light: Color(0xFFE5F7E7), text: Color(0xFF2D8A3E), name: '그린'),
  RoutineColor(bg: Color(0xFF4D96FF), light: Color(0xFFE0EDFF), text: Color(0xFF1A5FCC), name: '스카이'),
  RoutineColor(bg: Color(0xFFC77DFF), light: Color(0xFFF3E5FF), text: Color(0xFF7B2FBE), name: '라벤더'),
  RoutineColor(bg: Color(0xFFFF9F43), light: Color(0xFFFFF0DC), text: Color(0xFFCC6D00), name: '오렌지'),
  RoutineColor(bg: Color(0xFFF368E0), light: Color(0xFFFFE5FB), text: Color(0xFFA0229B), name: '핑크'),
];