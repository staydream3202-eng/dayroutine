# 데이루틴 (DayRoutine) — CLAUDE.md

## 앱의 핵심 목적과 철학

### 한 줄 요약
> "누구든 자신의 하루 사이클을 기준으로 루틴을 등록하고, 한눈에 확인할 수 있는 시간표 앱"

### 왜 만들었는가
기존 시간표 앱은 하루를 무조건 **00시~23시** 기준으로 표시한다.
하지만 야간 근무자, 새벽에 자는 사람, 오후에 기상하는 사람은
자정을 넘기는 일정이 **날짜 기준으로 쪼개져** 한눈에 자신의 하루 흐름을 보기 어렵다.

### 해결 방식
- **기본 뷰(00~23시)는 그대로 유지** — 일반적인 생활 패턴 사용자를 위해
- **커스텀 뷰 옵션 추가** — 사용자가 하루의 시작 시간을 직접 지정
  - 예: 22시 시작 설정 → 시간표가 `22시 → 23시 → 00시 → ... → 21시` 순으로 표시
  - 자정을 넘기는 일정도 **끊기지 않고 하나의 연속된 흐름**으로 표시
- 누구든 자신의 생활 패턴에 맞는 뷰를 선택해서 루틴을 등록하고 저장할 수 있음

### 핵심 사용자 경험
1. 자연어로 일정 입력 ("월~금 오후 9시~익일 오전 6시 야간근무")
2. 격자형 또는 원형 시간표로 시각화
3. 내 하루 시작점 기준으로 전체 사이클을 **한눈에** 확인

---

## 프로젝트 기본 정보

- **배포 URL**: https://dayroutine-66593.web.app
- **Firebase 프로젝트**: dayroutine-66593
- **GitHub**: https://github.com/staydream3202-eng/dayroutine
- **현재 버전**: v6.0
- **플랫폼**: Flutter Web
- **저장 방식**: SharedPreferences (로그인 없음, 로컬 저장)
- **데이터 키 버전**: `_v6` suffix (routines_v6 / app_settings_v6 / todos_v6)

---

## 기술 스택

```yaml
dependencies:
  shared_preferences: ^2.5.4
  uuid: ^4.5.3
  firebase_core: ^3.0.0
  intl: ^0.19.0
```

```bash
# 빌드 & 배포
flutter build web --release && firebase deploy --only hosting

# 클린 빌드
flutter clean && flutter pub get && flutter build web --release
```

---

## 파일 구조

```
lib/
├── main.dart                  ← _RootScreen: 랜딩↔홈 bool 상태 전환
├── models/
│   ├── routine.dart           ← startMinute/endMinute(10분 단위), crossMidnight
│   └── app_settings.dart      ← sleepNextDay, circleLabel, useWakeHourAsStart
├── screens/
│   ├── landing_screen.dart
│   ├── home_screen.dart       ← 4탭 (시간표/캘린더/To-do list/설정)
│   ├── calendar_screen.dart
│   ├── settings_screen.dart
│   ├── todo_screen.dart
│   └── login_screen.dart      ← 미사용, 빈 파일 유지 (삭제 금지)
├── services/
│   └── storage_service.dart
├── utils/
│   ├── parse_input.dart        ← 자연어 NLP 파서
│   └── colors.dart
└── widgets/
    ├── grid_view_widget.dart   ← 격자형 시간표
    └── circle_view_widget.dart ← 원형 시간표
web/
└── index.html                 ← Google Fonts CDN (Noto Sans KR) 포함 필수
```

---

## 핵심 모델

### Routine
```dart
class Routine {
  final String id, label;
  final List<String> days;          // ['월','화','수','목','금','토','일']
  final int startHour, endHour;     // 0~23, 1~24
  final int startMinute, endMinute; // 0,10,20,30,40,50 (10분 단위)
  final int colorIndex;
  final Color? customColor;
  final DateTime createdAt;

  bool get crossMidnight;  // 자정 초과 여부
  String get timeLabel;    // "9:00~10:30" 형식
}
```

### AppSettings
```dart
class AppSettings {
  final String themeColor;       // '0xFF667eea' 형식 (Color(int.parse()) 로 사용)
  final double fontSize;         // 0.8~1.4 배율
  final Map<String, SleepSchedule> sleepByDay;
  final bool perDaySleep;
  final bool useWakeHourAsStart; // true면 시간표 시작점 = 기상시간
  final String circleLabel;      // 원형 중앙 텍스트 (클릭 시 편집)
  final List<ScheduleLibraryItem> scheduleLibrary;
}

class SleepSchedule {
  final int sleepHour, wakeHour;
  final bool sleepNextDay; // true면 취침이 익일 오전(0~11시)으로 처리
}
```

### TodoItem
```dart
class TodoItem {
  final String id, label;
  final bool isDone, isRoutineBased;
  final String? routineId;
}
```

---

## 시간표 뷰 동작 규칙

### 격자형 (grid_view_widget.dart)
- 기본: 0~23시 전체를 스크롤 없이 한 화면에 표시 (rowH 자동 계산)
- useWakeHourAsStart = true이면 기상 시간부터 시작
- 익일 일정: 오늘(~24시) + 다음날(0시~) 분리 저장

### 원형 (circle_view_widget.dart)
- 상단 요일 탭 필터, 기본값 오늘 요일 자동 선택
- 익일 일정: 자정을 넘겨 연속 arc로 표시 (끊기지 않음)
- 중앙 텍스트: circleLabel 저장, 클릭 시 편집/삭제
- 일정 이름: arc 방향으로 회전하여 표시
- 시간 표시 토글 (1시간 단위)
- dayStartHour 설정 시 그 시간부터 원형 배치 시작

---

## 자연어 파싱 규칙 (parse_input.dart)

- 구분자: 쉼표(`,`) 또는 슬래시(`/`)로 복수 일정 구분
- 요일 범위: `월~금`, `월-금` → 배열 확장
- 구어체: `월욜`, `월날`, `화욜` 등 허용
- AM/PM 모호: `3시` 입력 시 → 팝업으로 오전/오후 사용자 선택
- 익일 키워드: `익일`, `다음날` → crossMidnight 플래그 설정
- 분 단위: `9시30분~11시` → startMinute=30, endMinute=0

---

## 코드 작성 규칙

1. **한국어 문자열**: 소스에 직접 작성 (`'월화수목금'`) — 유니코드 이스케이프(`\uc6d4`) 절대 사용 금지
2. **색상 범위 초과 방지**: `routineColors[r.colorIndex % routineColors.length]`
3. **null-safe 역직렬화**: `json['startMinute'] ?? 0` 형태로 항상 fallback 제공
4. **색상 API**: `withOpacity()` 대신 `withAlpha()` 사용
5. **상태 관리**: Provider 없음, StatefulWidget + setState 패턴
6. **저장 키**: 새 기능 추가 시에도 `_v6` suffix 유지
7. **빌드 확인**: 변경 후 반드시 `flutter build web --release` 성공 확인

---

## 주의사항

- `dart:html` deprecated 경고 있으나 이미지 저장 기능에 사용 중 — 동작 무관하므로 수정 불필요
- `login_screen.dart`는 빈 파일이지만 삭제 금지 (다른 곳에서 import 가능)
- `web/index.html`에 Noto Sans KR 폰트 CDN 없으면 한국어 깨짐 — 절대 제거 금지
- pixelRatio 3.0 고정 (이미지 저장 시 고해상도)
