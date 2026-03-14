// parse_input.dart v7 - allDay 지원, 아침/저녁/낮 prefix, 다음날/담날 hasNextDay
class ParsedRoutine {
  final List<String> days;
  final int startHour;
  final int endHour;
  final int startMinute;
  final int endMinute;
  final String label;
  final bool needsAmPmCheck;
  final bool endNeedsAmPmCheck;
  final bool crossMidnight;
  final bool isAllDay;

  const ParsedRoutine({
    required this.days,
    required this.startHour,
    required this.endHour,
    this.startMinute = 0,
    this.endMinute = 0,
    required this.label,
    this.needsAmPmCheck = false,
    this.endNeedsAmPmCheck = false,
    this.crossMidnight = false,
    this.isAllDay = false,
  });
}

const _dayOrder = ['월', '화', '수', '목', '금', '토', '일'];

const Map<String, int> _dayMap = {
  '월': 0, '월요일': 0, '월욜': 0, '월일': 0, '월날': 0,
  '화': 1, '화요일': 1, '화욜': 1, '화일': 1, '화날': 1,
  '수': 2, '수요일': 2, '수욜': 2, '수일': 2, '수날': 2,
  '목': 3, '목요일': 3, '목욜': 3, '목일': 3, '목날': 3,
  '금': 4, '금요일': 4, '금욜': 4, '금일': 4, '금날': 4,
  '토': 5, '토요일': 5, '토욜': 5, '토일': 5, '토날': 5,
  '일': 6, '일요일': 6, '일욜': 6, '일날': 6, '주일': 6,
  '매일': -1, '평일': -2, '주중': -2, '주말': -3,
};

// 하루종일 키워드
const _allDayKeywords = [
  '하루종일', '24시간', '풀타임', '하루 종일', '전체', '하루 전체',
  '하루전체', '전부', '풀로', '온종일', '웬종일',
];

// 시간+분 파싱: "오후 2시 30분", "14:30", "2시반"
// prefix 확장: 아침(→오전), 저녁(→오후), 낮(→오후 계열)
final _rangeTimePattern = RegExp(
  r'(오전|오후|새벽|낮|밤|아침|저녁)?\s*(\d{1,2})\s*시?\s*(?:(\d{1,2})\s*분?)?\s*(?:부터|에서)?\s*(?:~|-)\s*(?:익일|다음날|담날|다음\s*날)?\s*(오전|오후|새벽|낮|밤|아침|저녁)?\s*(\d{1,2})\s*시?\s*(?:(\d{1,2})\s*분?)?',
  caseSensitive: false,
);
final _fromToTimePattern = RegExp(
  r'(오전|오후|새벽|낮|밤|아침|저녁)?\s*(\d{1,2})\s*시?\s*(?:(\d{1,2})\s*분?)?\s*(?:부터|에서)\s*(?:익일|다음날|담날|다음\s*날)?\s*(오전|오후|새벽|낮|밤|아침|저녁)?\s*(\d{1,2})\s*시?\s*(?:(\d{1,2})\s*분?)?',
  caseSensitive: false,
);
final _singleTimePattern = RegExp(
  r'(오전|오후|새벽|낮|밤|아침|저녁)\s*(\d{1,2})\s*시\s*(?:(\d{1,2})\s*분?)?|(\d{1,2})\s*시\s*(?:(\d{1,2})\s*분?)?',
  caseSensitive: false,
);

List<String> parseDays(String raw) {
  raw = raw.trim();
  if (_dayMap[raw] == -1 || raw == '매일') return List.from(_dayOrder);
  if (_dayMap[raw] == -2 || raw == '평일' || raw == '주중') return ['월','화','수','목','금'];
  if (_dayMap[raw] == -3 || raw == '주말') return ['토','일'];

  final rr = RegExp(r'([가-힣a-z]{1,5})\s*(?:[~\-]|부터|에서)\s*([가-힣a-z]{1,5})', caseSensitive: false);
  final rm = rr.firstMatch(raw);
  if (rm != null) {
    final si = _tokenToDayIdx(rm.group(1)!);
    final ei = _tokenToDayIdx(rm.group(2)!);
    if (si >= 0 && ei >= 0) {
      if (si <= ei) return [for (var i = si; i <= ei; i++) _dayOrder[i]];
      return [...[for (var i = si; i < 7; i++) _dayOrder[i]], ...[for (var i = 0; i <= ei; i++) _dayOrder[i]]];
    }
  }

  final tokens = raw.split(RegExp(r'[,·、\s]+'));
  final result = <String>[];
  for (final t in tokens) {
    final idx = _tokenToDayIdx(t.trim());
    if (idx >= 0) result.add(_dayOrder[idx]);
  }
  if (result.isNotEmpty) return result.toSet().toList()..sort((a,b)=>_dayOrder.indexOf(a)-_dayOrder.indexOf(b));

  final known = _dayMap.keys.where((k) => (_dayMap[k]??-99) >= 0).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final found = <String>[];
  String rem = raw;
  for (final k in known) {
    if (rem.contains(k)) { found.add(_dayOrder[_dayMap[k]!]); rem = rem.replaceAll(k, ''); }
  }
  return found.toSet().toList()..sort((a,b)=>_dayOrder.indexOf(a)-_dayOrder.indexOf(b));
}

int _tokenToDayIdx(String t) {
  t = t.trim().toLowerCase();
  final v = _dayMap[t];
  if (v != null && v >= 0) return v;
  return -1;
}

int _applyAmPm(String prefix, int h) {
  final p = prefix.toLowerCase();
  // 오후 계열: 오후, 밤, 저녁, 낮 → PM
  if ((p == '오후' || p == '밤' || p == '저녁' || p == '낮') && h != 12) return h + 12;
  // 오전 계열: 오전, 새벽, 아침 → AM (12시는 0시로)
  if ((p == '오전' || p == '새벽' || p == '아침') && h == 12) return 0;
  return h;
}

bool _isAmbiguous(String prefix, int h) => prefix.isEmpty && h >= 1 && h <= 11;

// 분 보정: 10분 단위
int _roundMinute(int m) {
  final multiples = [0, 10, 20, 30, 40, 50];
  return multiples.reduce((a, b) => (m - a).abs() <= (m - b).abs() ? a : b);
}

List<ParsedRoutine>? parseInput(String input) {
  input = input.trim();
  if (input.isEmpty) return null;

  final segments = input.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final result = <ParsedRoutine>[];
  ParsedRoutine? lastParsed;

  for (final seg in segments) {
    final parsed = _parseOneSeg(seg, lastParsed);
    if (parsed != null && parsed.isNotEmpty) {
      result.addAll(parsed);
      lastParsed = parsed.last;
    }
  }
  return result.isEmpty ? null : result;
}

List<ParsedRoutine>? _parseOneSeg(String seg, ParsedRoutine? prev) {
  seg = seg.trim();
  if (seg.isEmpty) return null;

  // ── 하루종일 키워드 감지 ──────────────────────────────────
  for (final kw in _allDayKeywords) {
    if (seg.contains(kw)) {
      // 요일 추출
      final segWithout = seg.replaceAll(kw, ' ').trim();
      final days = _extractDays(segWithout, prev);
      if (days == null || days.isEmpty) return null;
      String label = _cleanLabel(segWithout, days);
      if (label.isEmpty) label = '하루종일';
      return [ParsedRoutine(days: days, startHour: 0, endHour: 24, label: label, isAllDay: true)];
    }
  }

  final hasNextDay = seg.contains('익일') || seg.contains('다음날') ||
      seg.contains('담날') || seg.contains('다음 날') || seg.contains('다음날');

  int startH = -1, endH = -1, startM = 0, endM = 0;
  bool ambig = false;
  bool endAmbig = false;
  bool cross = false;
  String rem = seg;

  // HH:MM ~ HH:MM 형식 먼저 처리
  final colonRangeReg = RegExp(r'(\d{1,2}):(\d{2})\s*(?:~|-|부터)\s*(?:익일|다음날|담날|다음\s*날)?\s*(\d{1,2}):(\d{2})');
  final colonRm = colonRangeReg.firstMatch(rem);
  if (colonRm != null) {
    startH = int.parse(colonRm.group(1)!); startM = _roundMinute(int.parse(colonRm.group(2)!));
    endH = int.parse(colonRm.group(3)!);   endM = _roundMinute(int.parse(colonRm.group(4)!));
    cross = hasNextDay || (endH * 60 + endM < startH * 60 + startM);
    rem = rem.replaceFirst(colonRm.group(0)!, ' ').trim();
  }

  if (startH == -1) {
    for (final pat in [_rangeTimePattern, _fromToTimePattern]) {
      final m = pat.firstMatch(rem);
      if (m != null) {
        final sp = m.group(1) ?? ''; final sn = int.tryParse(m.group(2) ?? '') ?? -1;
        final sm = int.tryParse(m.group(3) ?? '') ?? 0;
        final ep = m.group(4) ?? ''; final en = int.tryParse(m.group(5) ?? '') ?? -1;
        final em = int.tryParse(m.group(6) ?? '') ?? 0;
        if (sn >= 0 && en >= 0) {
          startH = sp.isEmpty ? sn : _applyAmPm(sp, sn); startM = _roundMinute(sm);
          endH   = ep.isEmpty ? en : _applyAmPm(ep, en); endM   = _roundMinute(em);
          ambig  = _isAmbiguous(sp, sn);
          endAmbig = _isAmbiguous(ep, en);
          cross  = hasNextDay || (endH * 60 + endM > 0 && endH * 60 + endM < startH * 60 + startM);
          if (endH == 0 && endM == 0) endH = 24;
          rem = rem.replaceFirst(m.group(0)!, ' ').trim();
          break;
        }
      }
    }
  }

  if (startH == -1) {
    final m = _singleTimePattern.firstMatch(rem);
    if (m != null) {
      final prefix = m.group(1) ?? '';
      final num = int.tryParse(m.group(2) ?? m.group(4) ?? '') ?? -1;
      final min = int.tryParse(m.group(3) ?? m.group(5) ?? '') ?? 0;
      if (num >= 0) {
        startH = prefix.isEmpty ? num : _applyAmPm(prefix, num);
        startM = _roundMinute(min);
        final totalEnd = startH * 60 + startM + 60;
        endH = totalEnd ~/ 60; endM = totalEnd % 60;
        if (endH > 24) endH = 24;
        ambig = _isAmbiguous(prefix, num);
        rem = rem.replaceFirst(m.group(0)!, ' ').trim();
      }
    }
  }

  if (startH == -1) return null;

  final days = _extractDays(rem, prev);
  if (days == null || days.isEmpty) return null;

  String label = _cleanLabel(rem, days);
  if (label.isEmpty) label = '일정';

  return [ParsedRoutine(
    days: days, startHour: startH, endHour: endH,
    startMinute: startM, endMinute: endM,
    label: label, needsAmPmCheck: ambig, endNeedsAmPmCheck: endAmbig, crossMidnight: cross,
  )];
}

// 요일 추출 (공통 함수)
List<String>? _extractDays(String rem, ParsedRoutine? prev) {
  List<String>? days;

  for (final kw in ['매일', '평일', '주중', '주말']) {
    if (rem.contains(kw)) { days = parseDays(kw); break; }
  }

  if (days == null) {
    final dr = RegExp(r'([가-힣]{1,4})\s*(?:[~\-]|부터|에서)\s*([가-힣]{1,4})');
    final dm = dr.firstMatch(rem);
    if (dm != null) {
      final si = _tokenToDayIdx(dm.group(1)!); final ei = _tokenToDayIdx(dm.group(2)!);
      if (si >= 0 && ei >= 0) {
        days = si <= ei ? [for (var i = si; i <= ei; i++) _dayOrder[i]]
            : [...[for(var i=si;i<7;i++) _dayOrder[i]],...[for(var i=0;i<=ei;i++) _dayOrder[i]]];
      }
    }
  }

  if (days == null) {
    final commaReg = RegExp(r'[가-힣]{1,4}(?:\s*[,·、]\s*[가-힣]{1,4})+');
    final cm = commaReg.firstMatch(rem);
    if (cm != null) {
      final parsed = parseDays(cm.group(0)!);
      if (parsed.isNotEmpty) { days = parsed; }
    }
  }

  if (days == null) {
    final known = _dayMap.keys.where((k) => (_dayMap[k]??-99) >= 0).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final k in known) {
      if (rem.contains(k)) { days = [_dayOrder[_dayMap[k]!]]; break; }
    }
  }

  if ((days == null || days.isEmpty) && prev != null) {
    days = prev.days;
  }
  return days;
}

// 레이블 정리 (공통 함수)
String _cleanLabel(String rem, List<String> days) {
  // 요일 관련 문자 제거
  final known = _dayMap.keys.where((k) => (_dayMap[k]??-99) >= 0).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  String label = rem;
  for (final k in [...['매일', '평일', '주중', '주말'], ...known]) {
    label = label.replaceAll(k, '');
  }
  // 하루종일 키워드 제거
  for (final kw in _allDayKeywords) {
    label = label.replaceAll(kw, '');
  }
  label = label.replaceAll('부터', '').replaceAll('에서', '').replaceAll('까지', '')
      .replaceAll('익일', '').replaceAll('다음날', '').replaceAll('담날', '')
      .replaceAll('다음 날', '').replaceAll('~', '')
      .replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return label;
}
