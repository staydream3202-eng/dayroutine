// calendar_screen.dart v8
// - 캘린더 통합 바(Bar) 뷰: 며칠 지속 루틴을 하나의 바로 표시
// - 텍스트 중앙 정렬
// - cross-midnight 연속 루틴(익일 0시 시작 split본)은 캘린더에서 제외
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../utils/colors.dart';

class CalendarScreen extends StatefulWidget {
  final List<Routine> routines;
  final void Function(Routine) onTap;

  const CalendarScreen({super.key, required this.routines, required this.onTap});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  DateTime get _today => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildMonthHeader(),
      _buildDayNameRow(),
      Expanded(
        child: SingleChildScrollView(
          child: _buildCalendarBody(),
        ),
      ),
    ]);
  }

  Widget _buildMonthHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
        ),
        Expanded(
          child: Text(
            '${_currentMonth.year}년 ${_currentMonth.month}월',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
        ),
      ]),
    );
  }

  Widget _buildDayNameRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: _dayNames.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: i == 5 ? Colors.blue[400] : i == 6 ? Colors.red[400] : Colors.grey[600],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarBody() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    // 월요일 기준 시작
    final startOffset = (firstDay.weekday - 1) % 7;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(children: List.generate(rows, (row) {
      return _buildWeekRow(row, startOffset, lastDay.day, firstDay);
    }));
  }

  Widget _buildWeekRow(int row, int startOffset, int lastDay, DateTime firstDay) {
    // 이번 주의 날짜 목록
    final weekDates = <DateTime?>[];
    for (int col = 0; col < 7; col++) {
      final cellIdx = row * 7 + col;
      final dayNum = cellIdx - startOffset + 1;
      if (dayNum < 1 || dayNum > lastDay) {
        weekDates.add(null);
      } else {
        weekDates.add(DateTime(_currentMonth.year, _currentMonth.month, dayNum));
      }
    }

    // 이번 주에 걸쳐있는 루틴 바 계산
    final weekBars = _calcWeekBars(weekDates);

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Column(children: [
        // 날짜 숫자 행
        Row(children: weekDates.asMap().entries.map((e) {
          final col = e.key;
          final date = e.value;
          final isToday = date != null &&
              date.year == _today.year &&
              date.month == _today.month &&
              date.day == _today.day;
          return Expanded(
            child: Container(
              height: 32,
              alignment: Alignment.center,
              child: date == null ? null : Container(
                width: 26, height: 26,
                decoration: isToday
                    ? BoxDecoration(color: const Color(0xFF667eea), shape: BoxShape.circle)
                    : null,
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.white : col == 5 ? Colors.blue[400] : col == 6 ? Colors.red[400] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList()),

        // 루틴 바 행들
        ...weekBars.map((barRow) => _buildBarRow(barRow, weekDates)),

        const SizedBox(height: 4),
      ]),
    );
  }

  // 이번 주 날짜들에 걸쳐있는 루틴을 바로 계산
  // 같은 라벨이 연속 요일에 걸쳐있으면 하나의 긴 바로 표시
  List<List<_CalBar?>> _calcWeekBars(List<DateTime?> weekDates) {
    final rows = <List<_CalBar?>>[];

    // 이번 주 요일 문자열
    final wdNames = ['월', '화', '수', '목', '금', '토', '일'];

    // cross-midnight split 된 익일 연속 루틴 ID 수집 (캘린더에서 제외)
    final continuationIds = <String>{};
    for (final r in widget.routines) {
      if (r.startHour != 0 || r.startMinute != 0) continue;
      for (final day in r.days) {
        final dayIdx = wdNames.indexOf(day);
        if (dayIdx < 0) continue;
        final prevDay = wdNames[(dayIdx - 1 + 7) % 7];
        final hasPrev = widget.routines.any((other) =>
          other.id != r.id &&
          other.days.contains(prevDay) &&
          other.label == r.label &&
          other.colorIndex == r.colorIndex &&
          other.endHour == 24 && other.endMinute == 0);
        if (hasPrev) { continuationIds.add(r.id); break; }
      }
    }

    // 시작 시간 기준 정렬, 익일 연속 루틴 제외
    final sortedRoutines = [...widget.routines]
      ..removeWhere((r) => continuationIds.contains(r.id))
      ..sort((a, b) => a.startTotal.compareTo(b.startTotal));

    // 각 루틴에 대해 이번 주의 연속 구간 찾기
    for (final r in sortedRoutines) {
      // 이번 주에서 이 루틴이 포함된 컬럼들
      final matchCols = <int>[];
      for (int col = 0; col < 7; col++) {
        final date = weekDates[col];
        if (date == null) continue;
        final wd = wdNames[col];
        if (r.days.contains(wd)) matchCols.add(col);
      }
      if (matchCols.isEmpty) continue;

      // 연속 구간 그룹화
      final groups = <List<int>>[];
      var current = [matchCols[0]];
      for (int i = 1; i < matchCols.length; i++) {
        if (matchCols[i] == matchCols[i - 1] + 1) {
          current.add(matchCols[i]);
        } else {
          groups.add(current);
          current = [matchCols[i]];
        }
      }
      groups.add(current);

      // 각 그룹을 바로 추가
      for (final group in groups) {
        final bar = _CalBar(
          label: r.label,
          startCol: group.first,
          endCol: group.last,
          color: r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg,
          routine: r,
        );
        // 빈 슬롯에 배치
        bool placed = false;
        for (final row in rows) {
          bool conflict = false;
          for (int col = bar.startCol; col <= bar.endCol; col++) {
            if (row[col] != null) { conflict = true; break; }
          }
          if (!conflict) {
            for (int col = bar.startCol; col <= bar.endCol; col++) {
              row[col] = bar;
            }
            placed = true;
            break;
          }
        }
        if (!placed) {
          final newRow = List<_CalBar?>.filled(7, null);
          for (int col = bar.startCol; col <= bar.endCol; col++) {
            newRow[col] = bar;
          }
          rows.add(newRow);
        }
      }
    }

    return rows;
  }

  Widget _buildBarRow(List<_CalBar?> barRow, List<DateTime?> weekDates) {
    return SizedBox(
      height: 20,
      child: Row(children: List.generate(7, (col) {
        final bar = barRow[col];
        if (bar == null) return const Expanded(child: SizedBox());
        // 바의 시작 컬럼에서만 렌더링 (나머지는 Expanded로 공간 차지)
        if (col != bar.startCol) return const SizedBox.shrink();

        final span = bar.endCol - bar.startCol + 1;
        return Expanded(
          flex: span,
          child: GestureDetector(
            onTap: () => widget.onTap(bar.routine),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
              decoration: BoxDecoration(
                color: bar.color.withAlpha(200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      })),
    );
  }
}

class _CalBar {
  final String label;
  final int startCol, endCol;
  final Color color;
  final Routine routine;

  _CalBar({required this.label, required this.startCol, required this.endCol, required this.color, required this.routine});
}
