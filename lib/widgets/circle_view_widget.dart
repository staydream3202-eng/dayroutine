// circle_view_widget.dart v6
// - 상단 요일 탭만 표시 (필터칩 제거)
// - 기본값: 오늘 요일 자동 선택 (클릭 안 된 상태가 기본 → 오늘 요일 하이라이트만)
// - 시간 표시 토글 (1시간 단위)
// - 중앙 텍스트 클릭 편집/삭제
// - 일정 이름 모두 표시
// - 자정 초과 일정 연속 띠
// - 요일 탭+배경색 통일
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../utils/colors.dart';

class CircleViewWidget extends StatefulWidget {
  final List<Routine> routines;
  final int dayStartHour;
  final String circleLabel;
  final void Function(String day, int startH, int startM, int endH, int endM)? onDragAdd;
  final void Function(String newLabel)? onLabelChanged;

  const CircleViewWidget({
    super.key,
    required this.routines,
    this.dayStartHour = 0,
    this.circleLabel = '',
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
  int _dragStartH = -1, _dragEndH = -1;

  @override
  void initState() {
    super.initState();
    // 기본값: 오늘 요일
    final wdMap = {1:'월',2:'화',3:'수',4:'목',5:'금',6:'토',7:'일'};
    _selectedDay = wdMap[DateTime.now().weekday] ?? '월';
  }

  Color get _bg => const Color(0xFFF0F2FF);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── 요일 탭 (배경색 통일) ──
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
                onTap: () => setState(() => _selectedDay = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF667eea) : isToday ? const Color(0xFF667eea).withAlpha(30) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : isToday ? const Color(0xFF667eea) : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),

      // ── 시간 표시 토글 ──
      Container(
        color: _bg,
        padding: const EdgeInsets.only(bottom: 6, right: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
            // 시간 레이블이 원 바깥에 그려지므로 충분한 여백 확보 (클리핑 방지)
            final labelMargin = _showTimeLabels ? 48.0 : 24.0;
            final size = (math.min(constraints.maxWidth, constraints.maxHeight) - labelMargin).clamp(100.0, double.infinity);
            final filtered = widget.routines.where((r) => r.days.contains(_selectedDay)).toList();

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
                      dayStartHour: widget.dayStartHour,
                      showTimeLabels: _showTimeLabels,
                      dragStartH: _dragStartH,
                      dragEndH: _dragEndH,
                      isDragging: _isDragging,
                    ),
                    child: Center(
                      child: _buildCenterLabel(size),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),

      // 드래그 안내
      if (_isDragging && _dragStartH >= 0 && _dragEndH >= 0)
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF667eea).withAlpha(60)),
          ),
          child: Text(
            '$_selectedDay요일  $_dragStartH:00 ~ $_dragEndH:00  (손가락을 떼면 등록)',
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
              ? Icon(Icons.edit_outlined, color: Colors.grey[300], size: 20)
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF667eea), fontWeight: FontWeight.bold),
                ),
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

  // 드래그
  Offset? _center;

  void _onDragStart(DragStartDetails d) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(d.globalPosition);
    _center = Offset(box.size.width / 2, box.size.height / 2);
    setState(() {
      _isDragging = true;
      _dragStartH = _posToHour(local, _center!);
      _dragEndH = _dragStartH;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_center == null) return;
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(d.globalPosition);
    setState(() => _dragEndH = _posToHour(local, _center!));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragStartH >= 0 && _dragEndH >= 0 && widget.onDragAdd != null) {
      final s = math.min(_dragStartH, _dragEndH);
      final e = math.max(_dragStartH, _dragEndH) + 1;
      widget.onDragAdd!(_selectedDay, s, 0, e > 24 ? 24 : e, 0);
    }
    setState(() { _isDragging = false; _dragStartH = -1; _dragEndH = -1; });
  }

  int _posToHour(Offset pos, Offset center) {
    final dx = pos.dx - center.dx, dy = pos.dy - center.dy;
    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    return ((angle / (2 * math.pi) * 24).floor() + widget.dayStartHour) % 24;
  }
}

// ── 원형 페인터 ──────────────────────────────────────────────
class _CirclePainter extends CustomPainter {
  final List<Routine> routines;
  final int dayStartHour;
  final bool showTimeLabels;
  final int dragStartH, dragEndH;
  final bool isDragging;

  _CirclePainter({
    required this.routines,
    required this.dayStartHour,
    required this.showTimeLabels,
    required this.dragStartH,
    required this.dragEndH,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = math.min(size.width, size.height) / 2 * 0.88;
    final innerR = outerR * 0.58;

    // 배경
    canvas.drawCircle(center, outerR, Paint()..color = const Color(0xFFE8ECFF));
    canvas.drawCircle(center, innerR, Paint()..color = Colors.white);

    // 눈금
    _drawTicks(canvas, center, outerR, innerR);

    // 일정 arc (자정 초과 포함)
    for (final r in routines) {
      final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
      _drawArc(canvas, center, outerR, innerR, r, color);
    }

    // 드래그 미리보기
    if (isDragging && dragStartH >= 0 && dragEndH >= 0) {
      final s = dragStartH < dragEndH ? dragStartH : dragEndH;
      final e = (dragStartH < dragEndH ? dragEndH : dragStartH) + 1;
      final fakeR = Routine(id:'', label:'', days:[], startHour: s, endHour: e, colorIndex: 0, createdAt: DateTime.now());
      _drawArc(canvas, center, outerR, innerR, fakeR, const Color(0xFF667eea).withAlpha(100));
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double outerR, double innerR) {
    final paint = Paint()..color = const Color(0xFFD0D4F0)..strokeWidth = 0.8;
    for (int h = 0; h < 24; h++) {
      final angle = _hourToAngle(h);
      // 볼드 위치는 실제 hour가 아닌 원 위의 위치(adjusted) 기준으로 고정
      final adjusted = (h - dayStartHour + 24) % 24;
      final isMajor = adjusted % 6 == 0;
      final tickInner = isMajor ? innerR + 2 : outerR - 8;
      final tickOuter = outerR;
      canvas.drawLine(
        center + Offset(math.cos(angle) * tickInner, math.sin(angle) * tickInner),
        center + Offset(math.cos(angle) * tickOuter, math.sin(angle) * tickOuter),
        paint..strokeWidth = isMajor ? 1.5 : 0.6,
      );

      // displayH: 실제 시각을 그대로 표시
      final displayH = h;

      if (showTimeLabels) {
        // 1시간 단위 전부 표시
        final tp = TextPainter(
          text: TextSpan(
            text: '$displayH',
            style: TextStyle(fontSize: isMajor ? 10 : 8, color: isMajor ? const Color(0xFF667eea) : const Color(0xFF9BA4CF)),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        final labelR = outerR + 12;
        tp.paint(canvas,
          center + Offset(math.cos(angle) * labelR - tp.width / 2, math.sin(angle) * labelR - tp.height / 2));
      } else if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(text: '$displayH시', style: const TextStyle(fontSize: 9, color: Color(0xFF8892C8))),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        final labelR = outerR + 12;
        tp.paint(canvas,
          center + Offset(math.cos(angle) * labelR - tp.width / 2, math.sin(angle) * labelR - tp.height / 2));
      }
    }
  }

  double _hourToAngle(int h) {
    final adjusted = (h - dayStartHour + 24) % 24;
    return adjusted / 24 * 2 * math.pi - math.pi / 2;
  }

  double _totalMinToAngle(int totalMin) {
    final startMin = dayStartHour * 60;
    final adjusted = (totalMin - startMin + 24 * 60) % (24 * 60);
    return adjusted / (24 * 60) * 2 * math.pi - math.pi / 2;
  }

  void _drawArc(Canvas canvas, Offset center, double outerR, double innerR, Routine r, Color color) {
    final sTotalMin = r.startHour * 60 + r.startMinute;
    final eTotalMin = r.endHour * 60 + r.endMinute;

    final startAngle = _totalMinToAngle(sTotalMin);
    final durationMin = r.crossMidnight
        ? (24 * 60 - sTotalMin + eTotalMin)
        : (eTotalMin - sTotalMin).clamp(10, 24 * 60);
    final sweepAngle = durationMin / (24 * 60) * 2 * math.pi;

    if (sweepAngle <= 0.01) return;

    final midR = (outerR + innerR) / 2;
    final arcW = (outerR - innerR) * 0.85;

    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: midR + arcW / 2), startAngle, sweepAngle);
    path.arcTo(Rect.fromCircle(center: center, radius: midR - arcW / 2), startAngle + sweepAngle, -sweepAngle, false);
    path.close();

    canvas.drawPath(path, Paint()..color = color.withAlpha(200)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1);

    // 라벨: 일정 이름 모두 표시 (호가 충분히 클 때)
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
      // 텍스트 회전 (호 방향으로)
      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(labelAngle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CirclePainter o) =>
      o.routines != routines || o.showTimeLabels != showTimeLabels ||
      o.dragStartH != dragStartH || o.dragEndH != dragEndH || o.isDragging != isDragging;
}
