// routine.dart v6 - startMinute, endMinute, customColor, crossMidnight 지원
import 'package:flutter/material.dart';

class Routine {
  final String id;
  final String label;
  final List<String> days;
  final int startHour;
  final int endHour;
  final int startMinute; // v6: 10분 단위
  final int endMinute;   // v6: 10분 단위
  final int colorIndex;
  final Color? customColor;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.label,
    required this.days,
    required this.startHour,
    required this.endHour,
    this.startMinute = 0,
    this.endMinute = 0,
    required this.colorIndex,
    this.customColor,
    required this.createdAt,
  });

  // 시작/종료를 분 단위로 변환 (편의 메서드)
  int get startTotal => startHour * 60 + startMinute;
  int get endTotal => endHour * 60 + endMinute;
  // 자정 초과 여부
  bool get crossMidnight => endTotal > 0 && endTotal < startTotal;

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      label: json['label'],
      days: List<String>.from(json['days']),
      startHour: json['startHour'],
      endHour: json['endHour'],
      startMinute: json['startMinute'] ?? 0,
      endMinute: json['endMinute'] ?? 0,
      colorIndex: json['colorIndex'] ?? 0,
      customColor: json['customColor'] != null ? Color(json['customColor']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'days': days,
    'startHour': startHour, 'endHour': endHour,
    'startMinute': startMinute, 'endMinute': endMinute,
    'colorIndex': colorIndex,
    'customColor': customColor?.toARGB32(),
    'createdAt': createdAt.toIso8601String(),
  };

  Routine copyWith({
    String? id, String? label, List<String>? days,
    int? startHour, int? endHour,
    int? startMinute, int? endMinute,
    int? colorIndex, Color? customColor, DateTime? createdAt,
  }) {
    return Routine(
      id: id ?? this.id, label: label ?? this.label, days: days ?? this.days,
      startHour: startHour ?? this.startHour, endHour: endHour ?? this.endHour,
      startMinute: startMinute ?? this.startMinute, endMinute: endMinute ?? this.endMinute,
      colorIndex: colorIndex ?? this.colorIndex,
      customColor: customColor ?? this.customColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeLabel {
    final s = startMinute == 0 ? '$startHour:00' : '$startHour:${startMinute.toString().padLeft(2,'0')}';
    final e = endMinute == 0 ? '$endHour:00' : '$endHour:${endMinute.toString().padLeft(2,'0')}';
    return '$s~$e';
  }
}
