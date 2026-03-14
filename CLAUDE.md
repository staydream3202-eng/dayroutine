# 데이루틴 (DayRoutine) - CLAUDE.md

초개인화 시간표/루틴 관리 웹앱 (Flutter Web v8.1)

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
  - **날짜 키워드**: `오늘` → 오늘 요일, `내일` → 내일 요일, `모레` → 모레 요일, `글피` → 글피 요일로 자동 변환
  - **파싱 실패 시 형식 안내 다이얼로그**: 인식 불가 입력 시 인라인 에러 대신 예시 포함 팝업 표시
  - **시간 prefix 통합**: `아침` → 오전, `저녁/낮` → 오후, `담날/다음날/다음 날` → 익일로 인식
  - **하루종일 키워드**: `하루종일`, `24시간`, `풀타임`, `하루 종일`, `전체`, `하루 전체`, `하루전체`, `전부`, `풀로`, `온종일`, `웬종일` → 0시~24시 전일 루틴 등록
- **오전/오후 불명확 팝업**: 시작 또는 종료 시간에 오전/오후 명시가 없을 경우 각각 팝업으로 확인
  - `"오후2시~7시"` → 종료 7시 오전/오후 선택 팝업 노출
  - `"8시~오후2시"` → 시작 8시 오전/오후 선택 팝업 노출
- **직접 설정 모달**: 요일·시간(10분 단위)·색상 선택 + **하루종일 체크박스**
- **수정 모달**: 요일·시간·색상 수정 + **하루종일 체크박스** (0시~24시이면 자동 체크)
- **격자뷰 / 원형뷰** 토글 (AppBar 우측)
- **원형뷰 드래그**: 시간 블록 드래그로 루틴 등록
- **원형뷰 기상 시간 기준 회전**: `useWakeHourAsStart` ON 시 기상 시간이 원형 시간표 상단(12시 방향) 기준점
  - 볼드 시간 레이블은 숫자 값이 아닌 위치(상/우/하/좌) 기준으로 고정 표시
- **원형뷰 익일 표시**: '익일 표시' 버튼 클릭 → 마지막 일정 선택 팝업 → 익일 일정까지 한 화면에 표시
  - 익일 시간 레이블: `24시`, `1시`, `2시` ... (기존 `익0`, `익1` → 변경)
  - 팝업에는 오늘 자정(24시)에 끝나는 cross-midnight 루틴의 익일 연속분만 표시
  - cross-midnight 루틴 없을 시 "익일까지 이어지는 일정이 없습니다." 다이얼로그 표시
  - `useWakeHourAsStart` ON 시 해당 버튼 숨김
- **격자뷰 익일 연속 표시**: `startHour > 0`일 때 익일로 이어지는 일정을 하나의 연속 블록으로 렌더링
- **이미지 저장**: 시간표 PNG 다운로드 (dart:html)
- **익일 일정**: 자정 초과 일정 자동 분리 저장 (오늘분 + 익일분)
- **시간표 설정 팁 팝업**: 익일 일정 등록 시 최초 1회만 표시 (`tip_nextday` SharedPreferences 키)

### To-do list 탭 (TodoScreen v7.1)
- **루틴 자동 연동**: 당일 요일에 해당하는 루틴만 자동 표시 (오늘이 월요일이면 월요일 루틴만)
- **하루 시작 배너**: 미시작 시 목록 상단에 배너로 노출 (탭하면 시작 기록)
- **하루 시작 버튼**: 클릭 시각을 하루의 시작으로 기록
- **하루 끝 버튼**: 클릭 시각을 하루의 끝으로 기록, 달성률 애니메이션 오버레이 표시
- **달성률 애니메이션**: 원형 프로그레스 바 (0% → 실제 달성률, 1.5초 애니메이션)
- **저장하고 자랑하기**: 달성률 카드를 PNG 이미지로 저장
- **하루 기준**: 하루 시작/끝 버튼 클릭 시각 기준. 버튼 누락 시 당일 시간표에서 가장 늦게 끝나는 루틴의 종료 시각 사용
- **전체 초기화 연동**: `resetToken` 변경 시 DB에서 다시 로드 (초기화 후 투두 잔존 버그 수정)

### 캘린더 탭 (CalendarScreen v8)
- 등록된 루틴을 달력에 시각화 (시작 시간 기준 정렬 표시)
- **cross-midnight 익일 연속분 제외**: 자정 넘어 이어지는 일정은 시작 요일에만 표시 (익일 분리본은 캘린더에서 숨김)
  - 감지 조건: `startHour==0 && startMinute==0` + 전날에 같은 라벨·colorIndex로 `endHour==24` 인 루틴 존재

### 설정 탭 (SettingsScreen v7)
- 테마 색상, 폰트 크기
- 수면&기상 시간 (요일별 개별 설정 or 공통)
  - 수면 설정 팝업에 **초기화 버튼** 추가 (0시/0시로 리셋 후 즉시 저장)
  - **익일 체크 표시 삭제** (오전 취침 시 자동으로 당일 새벽으로 인식)
- 기상 시간 기준 시간표 시작 토글
  - **perDaySleep + useWakeHourAsStart**: 요일별 개별 설정 ON 상태에서 토글 ON 시 최초 1회 안내 팝업 표시 (`tip_perday_wake` 키)
  - 안내 내용: "요일별 개별 수면&기상 설정 시 원형 시간표에만 적용됩니다."
  - 격자형은 항상 0시 기준 유지, 원형만 요일별 기상 시간 적용
- 스케줄 라이브러리 (루틴 세트 저장/불러오기)
- 원형 뷰 중앙 텍스트 설정
- **2단계 초기화 팝업**:
  - 1단계: 범위 선택 — "현재 시간표만 초기화" / "모든 데이터 초기화" / "취소"
  - 2단계: 최종 확인 — "이 작업은 되돌릴 수 없습니다." 경고 후 실행
  - 현재 시간표만: 루틴 목록만 삭제
  - 모든 데이터: 루틴 + 투두 리스트 + 하루 시작/끝 기록 + 스케줄 라이브러리 + **수면&기상 시간 설정** 전체 삭제

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
- 블록 텍스트: `min(colW * 0.10, height * 0.28) * fontSize).clamp(7, 14)` — colW·블록높이 모두 반영
  - `maxLines = (height / (fontSize + 4)).floor().clamp(1, 3)` — 블록 높이·폰트 기반 줄 수 동적 계산
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
- **요일 파싱 우선순위**: 날짜 키워드(`오늘/내일/모레/글피`) → 매일/평일/주말 → 범위(`월~금`) → 쉼표(`월,화`) → 단일 요일 순으로 탐색
- **날짜 키워드 변환**: `_dateOffsetToDay(offsetDays)` — `DateTime.now().weekday` 기준으로 요일 인덱스 계산 (오늘=+0, 내일=+1, 모레=+2, 글피=+3)
- **첫 사용 팁 패턴**: `StorageService.getTipShown(key)` / `setTipShown(key)` → `SharedPreferences` `tip_{key}` bool 키
  - 현재 키: `tip_nextday` (익일 일정 팁), `tip_perday_wake` (요일별 기상+격자 안내)
- **perDaySleep + useWakeHourAsStart 동작**:
  - 격자형: 항상 `startHour = 0` (perDay 여부 무관)
  - 원형: `wakeHoursByDay` 맵으로 요일별 기상 시간 전달 → 각 요일탭에서 해당 기상 시간을 상단 기준으로 회전
- **CircleViewWidget 파라미터 (v7.1)**:
  - `useWakeHourAsStart: bool` — 익일 버튼 숨김 여부 제어
  - `wakeHoursByDay: Map<String, int>?` — perDay 기상 시간 맵 (null이면 `dayStartHour` 단일값 사용)

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
| `getTipShown(key)` / `setTipShown(key)` | 첫 사용 팁 표시 여부 확인/기록 (`tip_{key}` 키) |

## 커밋 히스토리 (주요)
- `bed45a6` 로그인 화면 배포
- 버그 수정 + 반응형 UI 개선 (쉼표 요일 파싱, 투두 자동 노출, 격자/원형 반응형, 폰트 FOIT 해결)
- 2단계 초기화 팝업 구현 (시간표만 / 모든 데이터 선택 + 최종 확인)
- 격자형 시간표 UI 수정: 요일 헤더 색상 통일(토/일 강조 제거), 좌상단 코너 배경색 통일
- 직접 설정 모달 기본 시작 시간 0시로 변경 (기존 9시)
- 랜딩 화면 배지 2×2 고정 그리드 레이아웃 (Wrap → Column+Row, 모바일 3+1 깨짐 해결)
- **v7**: 오전/오후 불명확 시간 팝업(종료 시간 포함), 원형뷰 기상 시간 기준 타임라인 회전(볼드 위치 고정), 수면 설정 팝업 초기화 버튼 + 익일 체크 삭제, 전체 초기화 시 수면 설정도 초기화, PC 투두 달성 오버레이 스크롤 개선
- **v7.1**: 투두 당일 요일 필터링, 투두 초기화 resetToken, 원형뷰 익일 표시 버튼(마지막 일정 선택 팝업), 격자뷰 익일 연속 블록, 원형 중앙 연필 아이콘 삭제, 시간 prefix 확장(아침/저녁/낮/담날), 하루종일 키워드 + 체크박스, 팁 팝업 1회 표시, 캘린더 시작 시간 기준 정렬, perDaySleep+useWakeHourAsStart 안내 팝업
- **v8**: 원형뷰 익일 레이블 '익0/익1...' → '24시/1시...' 표기, 자연어 입력 쉼표 요일 후 일정명 쉼표 버그 수정, 격자뷰 블록 텍스트 폰트 colW·높이 동시 반영 개선, 캘린더 cross-midnight 익일 연속분 제외(시작 요일에만 표시), 원형뷰 익일 표시 팝업 cross-midnight 루틴만 필터링(없을 시 안내 다이얼로그)
- **v8.1**: 오늘/내일/모레/글피 날짜 키워드 → 당일 요일 자동 변환, 파싱 실패 시 형식 안내 팝업, 오늘 일정 등록 즉시 투두리스트 연동(리스트 참조 갱신으로 didUpdateWidget 감지)
