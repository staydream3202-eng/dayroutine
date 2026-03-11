import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../utils/colors.dart';

class GridViewWidget extends StatelessWidget {
  final List<Routine> routines;
  final Function(Routine) onTap;

  const GridViewWidget({super.key, required this.routines, required this.onTap});

  static const List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  static const int startHour = 7;
  static const int endHour = 22;
  static const double hourHeight = 60.0;
  static const double dayWidth = 48.0;
  static const double timeWidth = 36.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour + now.minute / 60.0;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: 36),
                ...List.generate(endHour - startHour, (i) {
                  return SizedBox(
                    height: hourHeight,
                    width: timeWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: Text(
                        '${startHour + i}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                }),
              ],
            ),
            ...days.map((day) {
              final dayRoutines = routines.where((r) => r.days.contains(day)).toList();
              return SizedBox(
                width: dayWidth,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: Text(day,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        ...List.generate(endHour - startHour, (i) {
                          return Container(
                            height: hourHeight,
                            decoration: BoxDecoration(
                              color: i % 2 == 0 ? Colors.white : Colors.grey[50],
                              border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                            ),
                          );
                        }),
                      ],
                    ),
                    ...dayRoutines.map((r) {
                      final top = 36 + (r.startHour - startHour) * hourHeight;
                      final height = (r.endHour - r.startHour) * hourHeight - 4;
                      final color = routineColors[r.colorIndex % routineColors.length];
                      return Positioned(
                        top: top,
                        left: 2,
                        right: 2,
                        height: height,
                        child: GestureDetector(
                          onTap: () => onTap(r),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.bg,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: color.bg.withAlpha(100),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${r.startHour}-${r.endHour}시',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    if (currentHour >= startHour && currentHour <= endHour)
                      Positioned(
                        top: 36 + (currentHour - startHour) * hourHeight,
                        left: 0,
                        right: 0,
                        child: Container(height: 1.5, color: Colors.red[400]),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}