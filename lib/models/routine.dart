import 'package:cloud_firestore/cloud_firestore.dart';

class Routine {
  final String id;
  final String label;
  final List<String> days;
  final int startHour;
  final int endHour;
  final int colorIndex;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.label,
    required this.days,
    required this.startHour,
    required this.endHour,
    required this.colorIndex,
    required this.createdAt,
  });

  factory Routine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Routine(
      id: doc.id,
      label: data['label'] ?? '',
      days: List<String>.from(data['days'] ?? []),
      startHour: data['startHour'] ?? 0,
      endHour: data['endHour'] ?? 1,
      colorIndex: data['colorIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'days': days,
      'startHour': startHour,
      'endHour': endHour,
      'colorIndex': colorIndex,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}