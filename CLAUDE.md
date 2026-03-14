# 데이루틴 (DayRoutine) - CLAUDE.md

초개인화 시간표/루틴 관리 웹앱 (Flutter Web v4)

## 프로젝트 개요

- **플랫폼**: Flutter Web (dart:html 사용, web-only)
- **배포**: Firebase Hosting
- **저장소**: SharedPreferences (로컬), Cloud Firestore (클라우드)
- **인증**: Firebase Auth + Google Sign-In

## 주요 파일 구조

```
lib/
├── main.dart                  # 앱 진입점, LandingScreen ↔ HomeScreen 라우팅
├── models/
│   ├── routine.dart           # Routine 모델 (v6: 10분 단위 startMinute/endMinute)
│   └── app_settings.dart      # AppSettings, SleepSchedule, TodoItem, ScheduleLibraryItem
├── screens/
│   ├── landing_screen.dart    # 랜딩(소개) 화면
│   ├── home_screen.dart       # 메인 - 시간표 탭 (격자/원형 뷰, 자연어 입력)
│   ├── calendar_screen.dart   # 캘린더 탭
│   ├── todo_screen.dart       # To-do list 탭 (v7)
│   └── settings_screen.dart   # 설정 탭
├── services/
│   ├── storage_service.dart   # SharedPreferences 저장소 (routines, settings, todos, daySession)
│   ├── auth_service.dart      # Firebase Auth
│   └── settings_service.dart  # 설정 관련 서비스
├── widgets/
│   ├── grid_view_widget.dart  # 격자형 시간표 위젯
│   └── circle_view_widget.dart# 원형(도넛) 시간표 위젯 (드래그 등록 지원)
└── utils/
    ├── colors.dart            # routineColors 팔레트
    └── parse_input.dart       # 자연어 입력 파서
```

## SharedPreferences 키 규칙

| 키 | 내용 |
|---|---|
| `routines_v6` | 전체 루틴 목록 (JSON array) |
| `app_settings_v6` | 앱 설정 (테마, 폰트, 수면 스케줄 등) |
| `todos_v6_{YYYY-MM-DD}` | 날짜별 투두 목록 |
| `day_session_v6_{YYYY-MM-DD}` | 날짜별 하루 시작/끝 시각 |

## 화면별 기능 요약

### 시간표 탭 (HomeScreen)
- **자연어 입력**: `"월~금 오후 2시 운동 / 일 오후 5시부터 익일 3시 작업"` 형식
  - 요일 구분: `~` 범위(`월~금`), 쉼표(`월,화,수`), 가운뎃점(`월·화`) 모두 지원
  - 요일 표기 형식: `월` `화요일` `월욜` `월날` `주일` 등 모든 형식 + 쉼표 조합 가능
  - 예: `"월요일,화욜,수날 오전10시 운동"` → 월·화·수 10시 등록
- **직접 설정 모달**: 요일·시간(10분 단위)·색상 선택
- **격자뷰 / 원형뷰** 토글 (AppBar 우측)
- **원형뷰 드래그**: 시간 블록 드래그로 루틴 등록
- **이미지 저장**: 시간표 PNG 다운로드 (dart:html)
- **익일 일정**: 자정 초과 일정 자동 분리 저장 (오늘분 + 익일분)

### To-do list 탭 (TodoScreen v7)
- **루틴 자동 연동**: 등록된 모든 루틴이 투두 항목으로 항상 자동 표시 (하루 시작 전에도 노출)
- **하루 시작 배너**: 미시작 시 목록 상단에 배너로 노출 (탭하면 시작 기록)
- **하루 시작 버튼**: 클릭 시각을 하루의 시작으로 기록
- **하루 끝 버튼**: 클릭 시각을 하루의 끝으로 기록, 달성률 애니메이션 오버레이 표시
- **달성률 애니메이션**: 원형 프로그레스 바 (0% → 실제 달성률, 1.5초 애니메이션)
- **저장하고 자랑하기**: 달성률 카드를 PNG 이미지로 저장
- **하루 기준**: 하루 시작/끝 버튼 클릭 시각 기준. 버튼 누락 시 당일 시간표에서 가장 늦게 끝나는 루틴의 종료 시각 사용

### 캘린더 탭 (CalendarScreen)
- 등록된 루틴을 달력에 시각화

### 설정 탭 (SettingsScreen)
- 테마 색상, 폰트 크기
- 수면&기상 시간 (요일별 개별 설정 or 공통)
- 기상 시간 기준 시간표 시작 토글
- 스케줄 라이브러리 (루틴 세트 저장/불러오기)
- 원형 뷰 중앙 텍스트 설정
- **2단계 초기화 팝업**:
  - 1단계: 범위 선택 — "현재 시간표만 초기화" / "모든 데이터 초기화" / "취소"
  - 2단계: 최종 확인 — "이 작업은 되돌릴 수 없습니다." 경고 후 실행
  - 현재 시간표만: 루틴 목록만 삭제
  - 모든 데이터: 루틴 + 투두 리스트 + 하루 시작/끝 기록 + 스케줄 라이브러리 전체 삭제

## 모델 주요 필드

### Routine
```dart
String id, label;
List<String> days;        // ['월','화','수','목','금','토','일'] 중 선택
int startHour, endHour;
int startMinute, endMinute; // 10분 단위 (0,10,20,30,40,50)
int colorIndex;
Color? customColor;
// 계산 getter: startTotal, endTotal (분 단위), crossMidnight, timeLabel
```

### AppSettings
```dart
String themeColor;        // '0xFF667eea' 형식
double fontSize;
Map<String, SleepSchedule> sleepByDay;
bool perDaySleep, useWakeHourAsStart;
String circleLabel;       // 원형 뷰 중앙 텍스트
List<ScheduleLibraryItem> scheduleLibrary;
```

### TodoItem
```dart
String id, label;
bool isDone, isRoutineBased;
String? routineId;
```

## 반응형 UI 규칙

### 격자형 시간표 (GridViewWidget)
- `colW = (maxWidth - 44) / 7` — 상한 없음, 화면 너비를 항상 꽉 채움
- 헤더 폰트: `(colW * 0.13 * fontSize).clamp(9, 18)` — colW에 비례
- 블록 텍스트: `(colW * 0.10 * fontSize).clamp(7, 14)` — colW에 비례
- 시간 레이블: `(rowH * 0.38 * fontSize).clamp(7, 12)` — rowH에 비례
- `colW < 32` 시 가로 스크롤 활성화 (모바일 극소 화면 대응)
- 요일 헤더 색상: 모두 `Colors.black87` (토/일 강조 없음)
- 좌상단 코너: `Container(color: Colors.white)` — 요일 헤더와 배경색 통일

### 원형 시간표 (CircleViewWidget)
- 시간 레이블 ON: `size = min(width, height) - 48` (레이블 클리핑 방지)
- 시간 레이블 OFF: `size = min(width, height) - 24`

### 폰트 로딩 (index.html)
- Google Fonts `display=block` + `<link rel="preload">` 사용
- `document.fonts.ready` AND `flutter-first-frame` 둘 다 완료 시 로딩 인디케이터 숨김
- 이중 대기 → 폰트 로드 전 Flutter 렌더링 방지 (네모 박스 FOIT 해결)

## 개발 주의사항

- **web-only**: `dart:html`을 직접 사용 (이미지 저장 등). `dart:io` 사용 불가
- **dart:html deprecation**: 경고가 나지만 현재 프로젝트에서는 의도적으로 사용 중 (home_screen, todo_screen 공통)
- **버전 키**: SharedPreferences 키에 `_v6` suffix 사용 중. 데이터 구조 변경 시 버전 올릴 것
- **익일 일정 처리**: crossMidnight 루틴은 오늘분/익일분으로 분리해 두 개의 Routine 객체로 저장
- **이미지 저장 패턴**: `RepaintBoundary(key: GlobalKey)` → `toImage(pixelRatio: 3.0)` → `dart:html Blob` → anchor click
- **요일 파싱 우선순위**: 매일/평일/주말 → 범위(`월~금`) → 쉼표(`월,화`) → 단일 요일 순으로 탐색

## SettingsScreen 콜백 인터페이스

| 콜백 | 타입 | 용도 |
|---|---|---|
| `onChanged` | `void Function(AppSettings)` | 설정 변경 즉시 저장 |
| `onRoutinesChanged` | `void Function(List<Routine>)` | 루틴 목록 교체 (라이브러리 불러오기, 시간표 초기화) |
| `onFullReset` | `Future<void> Function()` | 모든 사용자 데이터 초기화 (StorageService.clearAllUserData + scheduleLibrary 초기화) |

## StorageService 주요 메서드

| 메서드 | 설명 |
|---|---|
| `getRoutines()` / `replaceAllRoutines()` | 루틴 CRUD |
| `getSettings()` / `saveSettings()` | 앱 설정 읽기/쓰기 |
| `getTodos(dateKey)` / `saveTodos(dateKey, ...)` | 날짜별 투두 |
| `getDaySession(dateKey)` / `saveDaySession(...)` | 날짜별 하루 시작/끝 |
| `clearAllUserData()` | `routines_v6`, `todos_v6_*`, `day_session_v6_*` 키 전체 삭제 (설정 제외) |

## 커밋 히스토리 (주요)
- `bed45a6` 로그인 화면 배포
- 현재: 버그 수정 + 반응형 UI 개선 (쉼표 요일 파싱, 투두 자동 노출, 격자/원형 반응형, 폰트 FOIT 해결)
- 2단계 초기화 팝업 구현 (시간표만 / 모든 데이터 선택 + 최종 확인)
- 격자형 시간표 UI 수정: 요일 헤더 색상 통일(토/일 강조 제거), 좌상단 코너 배경색 통일
- 직접 설정 모달 기본 시작 시간 0시로 변경 (기존 9시)
- 랜딩 화면 배지 2×2 고정 그리드 레이아웃 (Wrap → Column+Row, 모바일 3+1 깨짐 해결)
