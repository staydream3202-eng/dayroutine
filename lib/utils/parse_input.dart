class ParsedRoutine {
  final List<String> days;
  final int startHour;
  final int endHour;
  final String label;

  ParsedRoutine({
    required this.days,
    required this.startHour,
    required this.endHour,
    required this.label,
  });
}

ParsedRoutine? parseInput(String input) {
  final allDays = ['월', '화', '수', '목', '금', '토', '일'];

  List<String> days = [];

  if (input.contains('매일')) {
    days = List.from(allDays);
  } else if (input.contains('평일')) {
    days = ['월', '화', '수', '목', '금'];
  } else if (input.contains('주말')) {
    days = ['토', '일'];
  } else if (RegExp(r'[월화수목금토일]~[월화수목금토일]').hasMatch(input)) {
    final match = RegExp(r'([월화수목금토일])~([월화수목금토일])').firstMatch(input);
    if (match != null) {
      final start = allDays.indexOf(match.group(1)!);
      final end = allDays.indexOf(match.group(2)!);
      if (start != -1 && end != -1) {
        days = allDays.sublist(start, end + 1);
      }
    }
  } else {
    for (final day in allDays) {
      if (input.contains(day)) days.add(day);
    }
  }

  if (days.isEmpty) return null;

  final timeMatch = RegExp(r'(\d{1,2})시[-~](\d{1,2})시').firstMatch(input);
  if (timeMatch == null) return null;

  final startHour = int.parse(timeMatch.group(1)!);
  final endHour = int.parse(timeMatch.group(2)!);

  if (startHour >= endHour) return null;

  String label = input
      .replaceAll(RegExp(r'[월화수목금토일~,]+'), '')
      .replaceAll(RegExp(r'\d{1,2}시[-~]\d{1,2}시'), '')
      .replaceAll(RegExp(r'매일|평일|주말'), '')
      .trim();

  if (label.isEmpty) label = '루틴';

  return ParsedRoutine(days: days, startHour: startHour, endHour: endHour, label: label);
}