// app_settings.dart v6
// - sleepNextDay 필드 추가 (취침 익일 체크박스)
// - useWakeHourAsStart 유지
// - 기본값 0시 유지
// - circleLabel (원형 중앙 텍스트) 추가

class SleepSchedule {
  final int sleepHour;
  final int sleepMinute; // v9: 10분 단위
  final int wakeHour;
  final int wakeMinute; // v9: 10분 단위
  final bool sleepNextDay;

  SleepSchedule({this.sleepHour = 0, this.sleepMinute = 0, this.wakeHour = 0, this.wakeMinute = 0, this.sleepNextDay = false});

  Map<String, dynamic> toJson() => {
    'sleepHour': sleepHour, 'sleepMinute': sleepMinute,
    'wakeHour': wakeHour, 'wakeMinute': wakeMinute,
    'sleepNextDay': sleepNextDay,
  };
  factory SleepSchedule.fromJson(Map<String, dynamic> j) => SleepSchedule(
    sleepHour: j['sleepHour'] ?? 0, sleepMinute: j['sleepMinute'] ?? 0,
    wakeHour: j['wakeHour'] ?? 0, wakeMinute: j['wakeMinute'] ?? 0,
    sleepNextDay: j['sleepNextDay'] ?? false,
  );
  SleepSchedule copyWith({int? sleepHour, int? sleepMinute, int? wakeHour, int? wakeMinute, bool? sleepNextDay}) => SleepSchedule(
    sleepHour: sleepHour ?? this.sleepHour, sleepMinute: sleepMinute ?? this.sleepMinute,
    wakeHour: wakeHour ?? this.wakeHour, wakeMinute: wakeMinute ?? this.wakeMinute,
    sleepNextDay: sleepNextDay ?? this.sleepNextDay,
  );
}

class ScheduleLibraryItem {
  final String id, name;
  final List<Map<String, dynamic>> routinesJson;
  final DateTime savedAt;

  ScheduleLibraryItem({required this.id, required this.name, required this.routinesJson, required this.savedAt});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'routinesJson': routinesJson,
    'savedAt': savedAt.toIso8601String(),
  };
  factory ScheduleLibraryItem.fromJson(Map<String, dynamic> j) => ScheduleLibraryItem(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    routinesJson: (j['routinesJson'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
    savedAt: DateTime.tryParse(j['savedAt'] ?? '') ?? DateTime.now(),
  );
}

class TodoItem {
  final String id, label;
  final bool isDone, isRoutineBased;
  final String? routineId;

  const TodoItem({required this.id, required this.label, required this.isDone, this.isRoutineBased = false, this.routineId});

  TodoItem copyWith({String? id, String? label, bool? isDone, bool? isRoutineBased, String? routineId}) =>
      TodoItem(id: id ?? this.id, label: label ?? this.label, isDone: isDone ?? this.isDone,
        isRoutineBased: isRoutineBased ?? this.isRoutineBased, routineId: routineId ?? this.routineId);

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'isDone': isDone, 'isRoutineBased': isRoutineBased, 'routineId': routineId};
  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(
    id: j['id'] ?? '', label: j['label'] ?? '', isDone: j['isDone'] ?? false,
    isRoutineBased: j['isRoutineBased'] ?? false, routineId: j['routineId'],
  );
}

class AppSettings {
  final String themeColor;
  final double fontSize;
  final Map<String, SleepSchedule> sleepByDay;
  final bool perDaySleep;
  final bool useWakeHourAsStart;
  final String circleLabel; // 원형 중앙 텍스트
  final List<ScheduleLibraryItem> scheduleLibrary;

  AppSettings({
    this.themeColor = '0xFF667eea',
    this.fontSize = 1.0,
    Map<String, SleepSchedule>? sleepByDay,
    this.perDaySleep = false,
    this.useWakeHourAsStart = false,
    this.circleLabel = '',
    this.scheduleLibrary = const [],
  }) : sleepByDay = sleepByDay ?? {
          for (final d in ['월','화','수','목','금','토','일'])
            d: SleepSchedule(sleepHour: 0, wakeHour: 0)
        };

  int get defaultWakeHour {
    if (sleepByDay.isEmpty) return 0;
    return sleepByDay.values.first.wakeHour;
  }

  AppSettings copyWith({
    String? themeColor, double? fontSize,
    Map<String, SleepSchedule>? sleepByDay,
    bool? perDaySleep, bool? useWakeHourAsStart,
    String? circleLabel,
    List<ScheduleLibraryItem>? scheduleLibrary,
  }) => AppSettings(
    themeColor: themeColor ?? this.themeColor,
    fontSize: fontSize ?? this.fontSize,
    sleepByDay: sleepByDay ?? this.sleepByDay,
    perDaySleep: perDaySleep ?? this.perDaySleep,
    useWakeHourAsStart: useWakeHourAsStart ?? this.useWakeHourAsStart,
    circleLabel: circleLabel ?? this.circleLabel,
    scheduleLibrary: scheduleLibrary ?? this.scheduleLibrary,
  );

  Map<String, dynamic> toJson() => {
    'themeColor': themeColor, 'fontSize': fontSize,
    'sleepByDay': sleepByDay.map((k, v) => MapEntry(k, v.toJson())),
    'perDaySleep': perDaySleep, 'useWakeHourAsStart': useWakeHourAsStart,
    'circleLabel': circleLabel,
    'scheduleLibrary': scheduleLibrary.map((e) => e.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    themeColor: j['themeColor'] ?? '0xFF667eea',
    fontSize: (j['fontSize'] ?? 1.0).toDouble(),
    sleepByDay: (j['sleepByDay'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), SleepSchedule.fromJson(Map<String, dynamic>.from(v)))) ?? {},
    perDaySleep: j['perDaySleep'] ?? false,
    useWakeHourAsStart: j['useWakeHourAsStart'] ?? false,
    circleLabel: j['circleLabel'] ?? '',
    scheduleLibrary: (j['scheduleLibrary'] as List?)
        ?.map((e) => ScheduleLibraryItem.fromJson(Map<String, dynamic>.from(e))).toList() ?? [],
  );
}
