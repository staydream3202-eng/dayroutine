import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/routine.dart';
import '../utils/colors.dart';
import 'package:intl/intl.dart';

class CircleViewWidget extends StatelessWidget {
  final List<Routine> routines;
  const CircleViewWidget({super.key, required this.routines});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(320, 320),
        painter: CirclePainter(routines: routines),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final List<Routine> routines;
  CirclePainter({required this.routines});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 - 10;
    final innerR = outerR * 0.42;

    canvas.drawCircle(
      Offset(cx, cy),
      outerR,
      Paint()..color = const Color(0xFFF8F9FA),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = Colors.white,
    );

    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi - pi / 2;
      final isMajor = i % 6 == 0;
      final p1 = Offset(cx + outerR * cos(angle), cy + outerR * sin(angle));
      final p2 = Offset(
        cx + (outerR + (isMajor ? 12 : 6)) * cos(angle),
        cy + (outerR + (isMajor ? 12 : 6)) * sin(angle),
      );
      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = isMajor ? Colors.grey.shade400 : Colors.grey.shade300
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
      if (isMajor) {
        final lp = Offset(
          cx + (outerR + 24) * cos(angle),
          cy + (outerR + 24) * sin(angle),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '$i시',
            style: TextStyle(color: Colors.grey[500], fontSize: 9),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
      }
    }

    for (final r in routines) {
      final color = routineColors[r.colorIndex % routineColors.length];
      final startAngle = (r.startHour / 24) * 2 * pi - pi / 2;
      final sweepAngle = ((r.endHour - r.startHour) / 24) * 2 * pi;
      final midR = (outerR + innerR) / 2;
      final paint = Paint()
        ..color = color.bg.withAlpha(217)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerR - innerR - 4;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: midR),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    final now = DateTime.now();
    final nowAngle = ((now.hour + now.minute / 60) / 24) * 2 * pi - pi / 2;
    canvas.drawLine(
      Offset(cx + innerR * cos(nowAngle), cy + innerR * sin(nowAngle)),
      Offset(cx + outerR * cos(nowAngle), cy + outerR * sin(nowAngle)),
      Paint()
        ..color = Colors.red.shade400
        ..strokeWidth = 2,
    );

    final today = DateFormat('M월 d일').format(DateTime.now());
    for (final item in [
      {'text': '데이루틴', 'size': 16.0, 'bold': true, 'dy': -10.0},
      {'text': today, 'size': 11.0, 'bold': false, 'dy': 12.0},
    ]) {
      final tp = TextPainter(
        text: TextSpan(
          text: item['text'] as String,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: item['size'] as double,
            fontWeight: (item['bold'] as bool) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, cy + (item['dy'] as double) - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}