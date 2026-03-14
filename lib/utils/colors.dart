import 'package:flutter/material.dart';

class RoutineColor {
  final Color bg;
  final Color light;
  final Color text;
  const RoutineColor({required this.bg, required this.light, required this.text});
}

const routineColors = [
  RoutineColor(bg: Color(0xFFFF6B6B), light: Color(0xFFFFEEEE), text: Color(0xFFCC0000)),
  RoutineColor(bg: Color(0xFF4ECDC4), light: Color(0xFFE8FAF9), text: Color(0xFF007A73)),
  RoutineColor(bg: Color(0xFFFFE66D), light: Color(0xFFFFFBE0), text: Color(0xFF997A00)),
  RoutineColor(bg: Color(0xFF95E1D3), light: Color(0xFFE8F8F5), text: Color(0xFF2E7D70)),
  RoutineColor(bg: Color(0xFF74B9FF), light: Color(0xFFE8F4FF), text: Color(0xFF0066CC)),
  RoutineColor(bg: Color(0xFFA29BFE), light: Color(0xFFF0EEFF), text: Color(0xFF4B44CC)),
  RoutineColor(bg: Color(0xFFFD79A8), light: Color(0xFFFFEEF4), text: Color(0xFFCC1155)),
  RoutineColor(bg: Color(0xFFE17055), light: Color(0xFFFFF0ED), text: Color(0xFF992200)),
];
