// circle_view_widget.dart v9
// - 익일 레이블 '익0/익1...' → '24시/1시...' 표기
// - 익일 표시 팝업: cross-midnight 루틴만 표시, 없을 시 안내 다이얼로그
// - 중앙 연필 아이콘 삭제
// - 익일 표시 버튼 (기상 시간 기준 사용 시 숨김)
// - wakeHoursByDay: 요일별 개별 기상 시간 지원
// - 기상 시간 기준 타임라인 회전 + 볼드 위치 고정
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../utils/colors.dart';

class CircleViewWidget extends StatefulWidget {
  final List<Routine> routines;
  final int dayStartHour;
  final String circleLabel;
  final bool useWakeHourAsStart;
  final Map<String, int>? wakeHoursByDay; // 요일별 기상 시간 (perDaySleep 시)
  final void Function(String day, int startH, int startM, int endH, int endM)? onDragAdd;
  final void Function(String newLabel)? onLabelChanged;

  const CircleViewWidget({
    super.key,
    required this.routines,
    this.dayStartHour = 0,
    this.circleLabel = '',
    this.useWakeHourAsStart = false,
    this.wakeHoursByDay,
    this.onDragAdd,
    this.onLabelChanged,
  });

  @override
  State<CircleViewWidget> createState() => _CircleViewWidgetState();
}

class _CircleViewWidgetState extends State<CircleViewWidget> {
  static const _days = ['월', '화', '수', '목', '금', '토', '일'];
  late String _selectedDay;
  bool _showTimeLabels = false;
  bool _isDragging = false;
  int _dragStartTotal = -1, _dragEndTotal = -1; // 분 단위 (10분 단위 스냅)

  // 익일 표시
  bool _nextDayEnabled = false;
  int? _nextDayEndTotal; // 익일 마지막 루틴의 endTotal (분, 0~24*60)

  @override
  void initState() {
    super.initState();
    final wdMap = {1:'월',2:'화',3:'수',4:'목',5:'금',6:'토',7:'일'};
    _selectedDay = wdMap[DateTime.now().weekday] ?? '월';
  }

  // 현재 선택 요일의 실질 기상 시간
  int get _effectiveDayStartHour {
    if (widget.wakeHoursByDay != null) {
      return widget.wakeHoursByDay![_selectedDay] ?? 0;
    }
    return widget.dayStartHour;
  }

  // 익일 표시 버튼 노출 여부
  bool get _showNextDayButton => !widget.useWakeHourAsStart;

  // 익일 표시 ON 시 총 시간 범위(분)
  int get _totalSpanMinutes =>
      (_nextDayEnabled && _nextDayEndTotal != null && _nextDayEndTotal! > 0)
          ? 24 * 60 + _nextDayEndTotal! + 60 // +60분 여유로 종료 시간 레이블 표시
          : 24 * 60;

  Color get _bg => const Color(0xFFF0F2FF);

  void _onDaySelected(String d) {
    setState(() {
      _selectedDay = d;
      // 요일 바꾸면 익일 표시 리셋
      _nextDayEnabled = false;
      _nextDayEndTotal = null;
    });
  }

  Future<void> _onNextDayToggle(bool value) async {
    if (!value) {
      setState(() { _nextDayEnabled = false; _nextDayEndTotal = null; });
      return;
    }
    final nextDayName = _days[(_days.indexOf(_selectedDay) + 1) % 7];

    // 오늘 루틴 중 자정(24시)에 끝나는 cross-midnight 루틴
    final todayCross = widget.routines
        .where((r) => r.days.contains(_selectedDay) && r.endHour == 24 && r.endMinute == 0)
        .toList();

    // 익일에서 0시 시작 + 오늘 cross-midnight 루틴과 라벨이 일치하는 것만
    final crossNext = widget.routines.where((r) {
      if (!r.days.contains(nextDayName)) return false;
      if (r.startHour != 0 || r.startMinute != 0) return false;
      return todayCross.any((t) => t.label == r.label);
    }).toList()..sort((a, b) => a.endTotal.compareTo(b.endTotal));

    if (crossNext.isEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('익일 표시', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: const Text('익일까지 이어지는 일정이 없습니다.', textAlign: TextAlign.center),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
        ),
      );
      return;
    }

    if (!mounted) return;
    final selected = await showDialog<Routine>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('오늘의 마지막 일정을 선택해주세요',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: crossNext.map((r) {
              final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
              return ListTile(
                leading: Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                title: Text(r.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('익일 ${r.timeLabel}', style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, r),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소'))],
      ),
    );

    if (selected == null) return;
    setState(() {
      _nextDayEnabled = true;
      _nextDayEndTotal = selected.endTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── 요일 탭 ──
      Container(
        color: _bg,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: _days.map((d) {
            final isSel = _selectedDay == d;
            final isToday = d == (() {
              final wdMap = {1:'월',2:'화',3:'수',4:'목',5:'금',6:'토',7:'일'};
              return wdMap[DateTime.now().weekday] ?? '';
            })();
            return Expanded(
              child: GestureDetector(
                onTap: () => _onDaySelected(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF667eea) : isToday ? const Color(0xFF667eea).withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(d, textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : isToday ? const Color(0xFF667eea) : Colors.grey[600],
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ),

      // ── 토글 행 (시간 표시 + 익일 표시) ──
      Container(
        color: _bg,
        padding: const EdgeInsets.only(bottom: 6, left: 12, right: 12),
        child: Row(children: [
          // 익일 표시 버튼
          if (_showNextDayButton) ...[
            Text('익일 표시', style: TextStyle(fontSize: 11, color: _nextDayEnabled ? const Color(0xFF667eea) : Colors.grey[500])),
            const SizedBox(width: 2),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: _nextDayEnabled,
                activeThumbColor: const Color(0xFF667eea),
                onChanged: _onNextDayToggle,
              ),
            ),
            const Spacer(),
          ] else
            const Spacer(),
          // 시간 표시
          Text('시간 표시', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: _showTimeLabels,
              activeThumbColor: const Color(0xFF667eea),
              onChanged: (v) => setState(() => _showTimeLabels = v),
            ),
          ),
        ]),
      ),

      // ── 원형 시간표 ──
      Expanded(
        child: Container(
          color: _bg,
          child: LayoutBuilder(builder: (ctx, constraints) {
            final labelMargin = _showTimeLabels ? 48.0 : 24.0;
            final size = (math.min(constraints.maxWidth, constraints.maxHeight) - labelMargin).clamp(100.0, double.infinity);

            final filtered = widget.routines.where((r) => r.days.contains(_selectedDay)).toList();

            // 익일 루틴
            List<Routine> nextDayRoutines = [];
            if (_nextDayEnabled && _nextDayEndTotal != null) {
              final nextDayName = _days[(_days.indexOf(_selectedDay) + 1) % 7];
              nextDayRoutines = widget.routines
                  .where((r) => r.days.contains(nextDayName) && r.startTotal < _nextDayEndTotal!)
                  .toList();
            }

            return Center(
              child: GestureDetector(
                onPanStart: _onDragStart,
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: SizedBox(
                  width: size, height: size,
                  child: CustomPaint(
                    painter: _CirclePainter(
                      routines: filtered,
                      nextDayRoutines: nextDayRoutines,
                      dayStartHour: _effectiveDayStartHour,
                      totalSpanMinutes: _totalSpanMinutes,
                      showTimeLabels: _showTimeLabels,
                      dragStartTotal: _dragStartTotal,
                      dragEndTotal: _dragEndTotal,
                      isDragging: _isDragging,
                    ),
                    child: Center(child: _buildCenterLabel(size)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),

      if (_isDragging && _dragStartTotal >= 0 && _dragEndTotal >= 0)
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF667eea).withAlpha(60)),
          ),
          child: Text(
            () {
              final sH = math.min(_dragStartTotal, _dragEndTotal) ~/ 60;
              final sM = math.min(_dragStartTotal, _dragEndTotal) % 60;
              final eTotal = math.min(math.max(_dragStartTotal, _dragEndTotal) + 60, 24 * 60);
              final eH = eTotal ~/ 60; final eM = eTotal % 60;
              return '$_selectedDay요일  $sH:${sM.toString().padLeft(2,'0')} ~ $eH:${eM.toString().padLeft(2,'0')}  (손가락을 떼면 등록)';
            }(),
            style: const TextStyle(fontSize: 11, color: Color(0xFF667eea), fontWeight: FontWeight.w600),
          ),
        ),
    ]);
  }

  Widget _buildCenterLabel(double size) {
    final innerR = size / 2 * 0.88 * 0.58;
    final label = widget.circleLabel;
    return GestureDetector(
      onTap: () => _editLabel(label),
      child: SizedBox(
        width: innerR * 1.8,
        height: innerR * 1.8,
        child: Center(
          child: label.isEmpty
              ? null // 연필 아이콘 삭제
              : Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF667eea), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _editLabel(String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('가운데 텍스트 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(
            hintText: '빈칸으로 두면 숨김',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (v) { widget.onLabelChanged?.call(v.trim()); Navigator.pop(ctx); },
        ),
        actions: [
          TextButton(
            onPressed: () { widget.onLabelChanged?.call(''); Navigator.pop(ctx); },
            child: const Text('지우기', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { widget.onLabelChanged?.call(ctrl.text.trim()); Navigator.pop(ctx); },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Offset? _center;

  void _onDragStart(DragStartDetails d) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(d.globalPosition);
    _center = Offset(box.size.width / 2, box.size.height / 2);
    setState(() {
      _isDragging = true;
      _dragStartTotal = _posToMinutes(local, _center!);
      _dragEndTotal = _dragStartTotal;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_center == null) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(d.globalPosition);
    setState(() => _dragEndTotal = _posToMinutes(local, _center!));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragStartTotal >= 0 && _dragEndTotal >= 0 && widget.onDragAdd != null) {
      final sTotal = math.min(_dragStartTotal, _dragEndTotal);
      final eTotal = math.min(math.max(_dragStartTotal, _dragEndTotal) + 60, 24 * 60);
      final sH = sTotal ~/ 60; final sM = sTotal % 60;
      final eH = eTotal ~/ 60; final eM = eTotal % 60;
      widget.onDragAdd!(_selectedDay, sH, sM, eH, eM);
    }
    setState(() { _isDragging = false; _dragStartTotal = -1; _dragEndTotal = -1; });
  }

  int _posToMinutes(Offset pos, Offset center) {
    final dx = pos.dx - center.dx, dy = pos.dy - center.dy;
    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    // 10분 단위 스냅
    final raw = angle / (2 * math.pi) * 24 * 60;
    final rounded = ((raw / 10).round() * 10) % (24 * 60);
    return (rounded + _effectiveDayStartHour * 60) % (24 * 60);
  }
}

// ── 원형 페인터 ──────────────────────────────────────────────
class _CirclePainter extends CustomPainter {
  final List<Routine> routines;
  final List<Routine> nextDayRoutines;
  final int dayStartHour;
  final int totalSpanMinutes; // 보통 24*60, 익일 ON 시 24*60+N
  final bool showTimeLabels;
  final int dragStartTotal, dragEndTotal; // 분 단위
  final bool isDragging;

  _CirclePainter({
    required this.routines,
    required this.nextDayRoutines,
    required this.dayStartHour,
    required this.totalSpanMinutes,
    required this.showTimeLabels,
    required this.dragStartTotal,
    required this.dragEndTotal,
    required this.isDragging,
  });

  bool get _isExtended => totalSpanMinutes > 24 * 60;
  int get _totalSpanHours => (totalSpanMinutes / 60).ceil();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = math.min(size.width, size.height) / 2 * 0.88;
    final innerR = outerR * 0.58;

    canvas.drawCircle(center, outerR, Paint()..color = const Color(0xFFE8ECFF));
    canvas.drawCircle(center, innerR, Paint()..color = Colors.white);

    _drawTicks(canvas, center, outerR, innerR);

    // 오늘 루틴
    for (final r in routines) {
      final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
      _drawArc(canvas, center, outerR, innerR, r, color, nextDayOffset: 0);
    }
    // 익일 루틴 (시간 +24h 오프셋)
    for (final r in nextDayRoutines) {
      final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
      _drawArc(canvas, center, outerR, innerR, r, color, nextDayOffset: 24 * 60);
    }

    // 드래그 미리보기 (10분 단위)
    if (isDragging && dragStartTotal >= 0 && dragEndTotal >= 0) {
      final sTotal = dragStartTotal < dragEndTotal ? dragStartTotal : dragEndTotal;
      final eTotal = (dragStartTotal < dragEndTotal ? dragEndTotal : dragStartTotal) + 60;
      final fakeR = Routine(id:'', label:'', days:[],
        startHour: sTotal ~/ 60, startMinute: sTotal % 60,
        endHour: eTotal ~/ 60, endMinute: eTotal % 60,
        colorIndex: 0, createdAt: DateTime.now());
      _drawArc(canvas, center, outerR, innerR, fakeR, const Color(0xFF667eea).withAlpha(100), nextDayOffset: 0);
    }
  }

  // 시간 h (0..totalSpanHours) → 각도
  double _hourToAngle(int h) {
    if (!_isExtended) {
      // 일반 모드: dayStartHour 기준 회전
      final adjusted = (h - dayStartHour + 24) % 24;
      return adjusted / 24 * 2 * math.pi - math.pi / 2;
    } else {
      // 익일 확장 모드: 0시가 맨 위 (dayStartHour=0 강제)
      return h / _totalSpanHours * 2 * math.pi - math.pi / 2;
    }
  }

  // totalMin(분) → 각도
  double _totalMinToAngle(int totalMin) {
    if (!_isExtended) {
      final startMin = dayStartHour * 60;
      final adjusted = (totalMin - startMin + 24 * 60) % (24 * 60);
      return adjusted / (24 * 60) * 2 * math.pi - math.pi / 2;
    } else {
      return totalMin / totalSpanMinutes * 2 * math.pi - math.pi / 2;
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double outerR, double innerR) {
    final paint = Paint()..color = const Color(0xFFD0D4F0)..strokeWidth = 0.8;
    final spanH = _totalSpanHours;

    for (int h = 0; h < spanH; h++) {
      final angle = _hourToAngle(h);

      // 볼드 결정
      final bool isMajor;
      if (!_isExtended) {
        final adjusted = (h - dayStartHour + 24) % 24;
        isMajor = adjusted % 6 == 0;
      } else {
        isMajor = h % 6 == 0;
      }

      final tickInner = isMajor ? innerR + 2 : outerR - 8;
      canvas.drawLine(
        center + Offset(math.cos(angle) * tickInner, math.sin(angle) * tickInner),
        center + Offset(math.cos(angle) * outerR, math.sin(angle) * outerR),
        paint..strokeWidth = isMajor ? 1.5 : 0.6,
      );

      // 레이블
      final String displayText;
      if (h < 24) {
        if (showTimeLabels) {
          displayText = '$h';
        } else if (isMajor) {
          displayText = '$h시';
        } else {
          displayText = '';
        }
      } else {
        // 익일 표시: 0 → '24시', 1 → '1시', ...
        final nd = h - 24;
        if (showTimeLabels) {
          displayText = nd == 0 ? '24' : '$nd';
        } else if (isMajor) {
          displayText = nd == 0 ? '24시' : '$nd시';
        } else {
          displayText = '';
        }
      }

      if (displayText.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: displayText,
            style: TextStyle(
              fontSize: (showTimeLabels ? (isMajor ? 10 : 8) : 9),
              color: isMajor ? const Color(0xFF667eea) : const Color(0xFF9BA4CF),
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        tp.layout();
        final labelR = outerR + 12;
        tp.paint(canvas,
          center + Offset(math.cos(angle) * labelR - tp.width / 2, math.sin(angle) * labelR - tp.height / 2));
      }
    }
  }

  void _drawArc(Canvas canvas, Offset center, double outerR, double innerR,
      Routine r, Color color, {required int nextDayOffset}) {
    final sTotalMin = r.startHour * 60 + r.startMinute + nextDayOffset;
    int eTotalMin = r.endHour * 60 + r.endMinute + nextDayOffset;

    // crossMidnight 처리 (nextDayOffset이 없는 오늘 루틴만)
    int durationMin;
    if (nextDayOffset == 0 && r.crossMidnight) {
      durationMin = (24 * 60 - (r.startHour * 60 + r.startMinute) + (r.endHour * 60 + r.endMinute));
    } else {
      durationMin = (eTotalMin - sTotalMin).clamp(10, totalSpanMinutes);
    }

    if (durationMin <= 0) return;

    final startAngle = _totalMinToAngle(sTotalMin);
    final sweepAngle = durationMin / totalSpanMinutes * 2 * math.pi;
    if (sweepAngle <= 0.01) return;

    final midR = (outerR + innerR) / 2;
    final arcW = (outerR - innerR) * 0.85;

    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: midR + arcW / 2), startAngle, sweepAngle);
    path.arcTo(Rect.fromCircle(center: center, radius: midR - arcW / 2), startAngle + sweepAngle, -sweepAngle, false);
    path.close();

    // 익일 루틴은 약간 투명하게
    final alpha = nextDayOffset > 0 ? 160 : 200;
    canvas.drawPath(path, Paint()..color = color.withAlpha(alpha)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1);

    if (r.label.isNotEmpty && sweepAngle > 0.2) {
      final labelAngle = startAngle + sweepAngle / 2;
      final labelPos = center + Offset(math.cos(labelAngle) * midR, math.sin(labelAngle) * midR);
      final tp = TextPainter(
        text: TextSpan(
          text: r.label,
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: arcW * 2.2);
      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(labelAngle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CirclePainter o) =>
      o.routines != routines || o.nextDayRoutines != nextDayRoutines ||
      o.showTimeLabels != showTimeLabels || o.dayStartHour != dayStartHour ||
      o.totalSpanMinutes != totalSpanMinutes ||
      o.dragStartTotal != dragStartTotal || o.dragEndTotal != dragEndTotal || o.isDragging != isDragging;
}
