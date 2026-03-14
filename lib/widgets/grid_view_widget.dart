// grid_view_widget.dart v8
// - 스크롤 없이 0~23시 한 화면에 표시
// - 이미지 저장 시 전체 캡처 (forExport)
// - 익일 일정: 오늘 오후8시~0시 + 다음날 0시~3시 분리 표시
// - 10분 단위 렌더링 지원
// - 블록 텍스트: colW·블록 높이 기반 폰트 자동 조절, maxLines 동적 계산
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../utils/colors.dart';

class GridViewWidget extends StatelessWidget {
  final List<Routine> routines;
  final void Function(Routine) onTap;
  final double fontSize;
  final int startHour;
  final bool forExport;

  const GridViewWidget({
    super.key,
    required this.routines,
    required this.onTap,
    this.fontSize = 1.0,
    this.startHour = 0,
    this.forExport = false,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    const totalHours = 24;
    const headerH = 36.0;
    const timeColW = 44.0;

    return LayoutBuilder(builder: (ctx, constraints) {
      // forExport 시 고정 크기, 아니면 화면 너비를 꽉 채우도록 (상한 제거)
      final double colW = forExport ? 80.0 : ((constraints.maxWidth - timeColW) / 7).clamp(32.0, double.infinity);
      // 스크롤 없이 한 화면에 딱 맞게 rowH 계산
      final double availH = forExport ? (totalHours * 28.0) : (constraints.maxHeight - headerH).clamp(totalHours * 14.0, double.infinity);
      final double rowH = forExport ? 28.0 : (availH / totalHours).clamp(14.0, 48.0);
      final totalW = timeColW + colW * 7;
      final totalH = headerH + rowH * totalHours;

      Widget content = Column(children: [
        // 요일 헤더
        SizedBox(
          height: headerH,
          child: Row(children: [
            Container(
              width: timeColW,
              height: headerH,
              color: Colors.white,
            ),
            ...days.map((d) => SizedBox(
              width: colW,
              child: Container(
                height: headerH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                    right: BorderSide(color: Colors.grey[100]!),
                  ),
                ),
                child: Center(
                  child: Text(d, style: TextStyle(
                    // colW에 비례해 헤더 폰트 크기 조정 (PC에서 자동으로 커짐)
                    fontSize: (colW * 0.13 * fontSize).clamp(9.0, 18.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )),
                ),
              ),
            )),
          ]),
        ),
        // 시간표 본체
        Expanded(
          child: SizedBox(
            width: totalW,
            child: Stack(children: [
              // 배경 격자
              ..._buildGrid(days, rowH, colW, timeColW, totalHours),
              // 일정 블록
              ..._buildBlocks(days, rowH, colW, timeColW, totalHours),
            ]),
          ),
        ),
      ]);

      if (forExport) {
        return SizedBox(
          width: totalW,
          height: totalH,
          child: content,
        );
      }
      // 가로 스크롤 (좁은 화면)
      final bool needHScroll = constraints.maxWidth < totalW;
      if (needHScroll) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: totalW, height: constraints.maxHeight, child: content),
        );
      }
      return content;
    });
  }

  List<Widget> _buildGrid(List<String> days, double rowH, double colW, double timeColW, int totalHours) {
    final widgets = <Widget>[];
    for (int i = 0; i < totalHours; i++) {
      final displayHour = (startHour + i) % 24;
      final y = i * rowH;
      final isMajor = i % 6 == 0;
      // 시간 레이블
      widgets.add(Positioned(
        top: y + 1,
        left: 0,
        width: timeColW - 2,
        child: Text(
          '$displayHour',
          textAlign: TextAlign.right,
          // rowH 기반: 셀 높이에 맞게 시간 레이블 크기 조정
          style: TextStyle(fontSize: (rowH * 0.38 * fontSize).clamp(7.0, 12.0), color: isMajor ? Colors.grey[600] : Colors.grey[400]),
        ),
      ));
      // 수평선
      widgets.add(Positioned(
        top: y,
        left: timeColW,
        width: colW * days.length,
        height: 0.5,
        child: Container(color: isMajor ? Colors.grey[250] : Colors.grey[100]),
      ));
    }
    // 수직선
    for (int di = 0; di < days.length; di++) {
      widgets.add(Positioned(
        top: 0, left: timeColW + colW * di, width: 0.5,
        height: rowH * totalHours,
        child: Container(color: Colors.grey[150]),
      ));
    }
    return widgets;
  }

  // 익일로 이어지는 루틴의 연속 부분을 찾아 반환 (startHour>0일 때 사용)
  Routine? _findContinuation(String nextDay, Routine todayPart) {
    for (final c in routines) {
      if (c.days.contains(nextDay) &&
          c.label == todayPart.label &&
          c.colorIndex == todayPart.colorIndex &&
          c.startHour == 0 && c.startMinute == 0) {
        return c;
      }
    }
    return null;
  }

  List<Widget> _buildBlocks(List<String> days, double rowH, double colW, double timeColW, int totalHours) {
    final widgets = <Widget>[];

    // startHour>0일 때, 다음날 0시 시작 루틴 중 "합쳐진" 것들의 ID 수집
    final mergedIds = <String>{};
    if (startHour > 0) {
      for (int di = 0; di < days.length; di++) {
        final nextDay = days[(di + 1) % days.length];
        for (final r in routines.where((r) => r.days.contains(days[di]) && r.endHour == 24 && r.endMinute == 0)) {
          final cont = _findContinuation(nextDay, r);
          if (cont != null) mergedIds.add(cont.id);
        }
      }
    }

    for (int di = 0; di < days.length; di++) {
      final day = days[di];
      final nextDay = days[(di + 1) % days.length];
      final dayRoutines = routines.where((r) => r.days.contains(day) && !mergedIds.contains(r.id)).toList();

      for (final r in dayRoutines) {
        final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
        final textColor = r.customColor ?? routineColors[r.colorIndex % routineColors.length].text;

        final sTotalMin = r.startHour * 60 + r.startMinute;
        int eTotalMin = r.endHour * 60 + r.endMinute;

        // startHour>0이고 오늘 부분이 24시에 끝나면 → 익일 연속 부분 찾아 합치기
        if (startHour > 0 && r.endHour == 24 && r.endMinute == 0) {
          final cont = _findContinuation(nextDay, r);
          if (cont != null) {
            eTotalMin = cont.endHour * 60 + cont.endMinute + 24 * 60;
          }
        }

        final startIdxMin = (sTotalMin - startHour * 60 + 24 * 60) % (24 * 60);
        final durationMin = r.crossMidnight
            ? (24 * 60 - sTotalMin + (r.endHour * 60 + r.endMinute))
            : (eTotalMin - sTotalMin).clamp(10, 48 * 60);

        final top = startIdxMin / 60.0 * rowH;
        final height = (durationMin / 60.0 * rowH).clamp(rowH * 0.3, rowH * totalHours.toDouble());
        final left = timeColW + di * colW;

        widgets.add(Positioned(
          top: top,
          left: left + 1,
          width: colW - 2,
          height: height,
          child: GestureDetector(
            onTap: () => onTap(r),
            child: Container(
              decoration: BoxDecoration(
                color: color.withAlpha(220),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color, width: 0.5),
              ),
              child: height >= rowH * 0.7
                  ? () {
                      // colW와 블록 높이를 모두 고려한 폰트 크기 계산
                      final blockFontSize = (math.min(colW * 0.10, height * 0.28) * fontSize).clamp(7.0, 14.0);
                      final maxLn = (height / (blockFontSize + 4)).floor().clamp(1, 3);
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            r.label,
                            textAlign: TextAlign.center,
                            maxLines: maxLn,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: blockFontSize,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }()
                  : null,
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
