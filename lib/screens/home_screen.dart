// home_screen.dart v6
// - To-do list 워딩 통일
// - 로고 클릭 → 랜딩 이동
// - 직접 설정 요일 한 줄 (모바일)
// - 익일 팝업 안내
// - 이미지 저장 전체 캡처
// - 10분 단위 등록
// - 원형 드래그 + circleLabel 연동
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import '../models/routine.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../utils/colors.dart';
import '../utils/parse_input.dart';
import '../widgets/grid_view_widget.dart';
import '../widgets/circle_view_widget.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'todo_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoLanding;
  const HomeScreen({super.key, this.onGoLanding});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _inputCtrl = TextEditingController();
  final _uuid = const Uuid();
  final GlobalKey _repaintKey = GlobalKey();

  List<Routine> _routines = [];
  AppSettings _settings = AppSettings();
  bool _loading = true;
  bool _saving = false;
  int _colorIndex = 0;
  String? _errorText;
  int _tabIndex = 0;
  int _viewIndex = 0; // 0=격자, 1=원형

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await _storage.getRoutines();
    final s = await _storage.getSettings();
    setState(() { _routines = r; _settings = s; _colorIndex = r.length; _loading = false; });
  }

  Future<void> _saveSettings(AppSettings s) async {
    await _storage.saveSettings(s);
    setState(() => _settings = s);
  }

  Future<void> _replaceRoutines(List<Routine> routines) async {
    await _storage.replaceAllRoutines(routines);
    setState(() { _routines = routines; _colorIndex = routines.length; });
  }

  Future<void> _fullReset() async {
    await _storage.clearAllUserData();
    final defaultSleep = {for (final d in ['월','화','수','목','금','토','일']) d: SleepSchedule()};
    final resetSettings = _settings.copyWith(scheduleLibrary: [], sleepByDay: defaultSleep);
    await _storage.saveSettings(resetSettings);
    setState(() { _routines = []; _colorIndex = 0; _settings = resetSettings; });
  }

  int get _wakeHour => _settings.useWakeHourAsStart ? _settings.defaultWakeHour : 0;
  Color get _themeColor => Color(int.parse(_settings.themeColor));

  // ── 자연어 입력 ──────────────────────────────────────────────
  Future<void> _addRoutine() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) { setState(() => _errorText = '일정을 입력해주세요'); return; }

    final list = parseInput(text);
    if (list == null || list.isEmpty) {
      setState(() => _errorText = '형식을 확인해주세요\n예: 월~금 오후 2시 운동 / 일 오후 5시부터 익일 3시 작업');
      return;
    }

    bool hasNextDay = false;
    final resolved = <ParsedRoutine>[];

    for (final p in list) {
      if (p.crossMidnight) hasNextDay = true;

      if (p.needsAmPmCheck || p.endNeedsAmPmCheck) {
        int newStart = p.startHour;
        int newEnd = p.endHour;

        if (p.needsAmPmCheck) {
          final choice = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Icon(Icons.access_time, color: _themeColor),
                const SizedBox(width: 8),
                Text('시작 ${p.startHour}시 — 오전/오후?'),
              ]),
              content: Text('"${p.label}" 일정의 시작 시간을 선택해주세요'),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx, 'am'), child: Text('오전 ${p.startHour}시')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx, 'pm'),
                  child: Text('오후 ${p.startHour}시', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (choice == null) return;
          newStart = choice == 'pm' ? p.startHour + 12 : p.startHour;
          // 단일 시간 패턴(종료 시간 명시 없음)이면 종료 시간도 함께 조정
          if (!p.endNeedsAmPmCheck && p.endHour == p.startHour + 1) {
            newEnd = newStart + 1;
          }
        }

        if (p.endNeedsAmPmCheck) {
          final choice = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Icon(Icons.access_time, color: _themeColor),
                const SizedBox(width: 8),
                Text('종료 ${p.endHour}시 — 오전/오후?'),
              ]),
              content: Text('"${p.label}" 일정의 종료 시간을 선택해주세요'),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx, 'am'), child: Text('오전 ${p.endHour}시')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx, 'pm'),
                  child: Text('오후 ${p.endHour}시', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (choice == null) return;
          newEnd = choice == 'pm' ? p.endHour + 12 : p.endHour;
        }

        resolved.add(ParsedRoutine(
          days: p.days, label: p.label,
          startHour: newStart, endHour: newEnd,
          startMinute: p.startMinute, endMinute: p.endMinute,
        ));
      } else {
        resolved.add(p);
      }
    }

    for (final p in resolved) {
      // 익일 일정이면 격자형용으로 분리 저장
      if (p.crossMidnight) {
        // 오늘 부분 (startHour ~ 24)
        final r1 = Routine(id: _uuid.v4(), label: p.label, days: p.days,
          startHour: p.startHour, endHour: 24, startMinute: p.startMinute, endMinute: 0,
          colorIndex: _colorIndex % routineColors.length, createdAt: DateTime.now());
        await _storage.addRoutine(r1); _routines.add(r1); _colorIndex++;

        // 다음날 부분 (0 ~ endHour)
        final nextDays = p.days.map((d) {
          final idx = ['월','화','수','목','금','토','일'].indexOf(d);
          return ['월','화','수','목','금','토','일'][(idx + 1) % 7];
        }).toList();
        final r2 = Routine(id: _uuid.v4(), label: p.label, days: nextDays,
          startHour: 0, endHour: p.endHour, startMinute: 0, endMinute: p.endMinute,
          colorIndex: _colorIndex % routineColors.length, createdAt: DateTime.now());
        await _storage.addRoutine(r2); _routines.add(r2); _colorIndex++;
      } else {
        final r = Routine(id: _uuid.v4(), label: p.label, days: p.days,
          startHour: p.startHour, endHour: p.endHour,
          startMinute: p.startMinute, endMinute: p.endMinute,
          colorIndex: _colorIndex % routineColors.length, createdAt: DateTime.now());
        await _storage.addRoutine(r); _routines.add(r); _colorIndex++;
      }
    }

    setState(() { _errorText = null; _inputCtrl.clear(); });
    _showSnack('${resolved.length}개 일정 등록 완료 ✅');

    // 익일 일정 등록 시 팝업 안내
    if (hasNextDay && mounted) {
      Future.delayed(const Duration(milliseconds: 400), () => _showNextDayPopup());
    }
  }

  void _showNextDayPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.tips_and_updates, color: _themeColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('시간표 설정 팁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _themeColor.withAlpha(15), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '00시가 기준이 아닌,\n나의 루틴에 맞는 시간표 설정하기',
              style: TextStyle(fontWeight: FontWeight.bold, color: _themeColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '기상 시간 기준으로 시간표를 변경하고\n익일 일정까지 오늘의 시간표에서\n한 눈에 확인하세요!',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(ctx); setState(() => _tabIndex = 3); },
            child: const Text('설정으로 이동', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 드래그 등록 (원형) ──────────────────────────────────────
  Future<void> _onDragAdd(String day, int startH, int startM, int endH, int endM) async {
    final labelCtrl = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$day요일 $startH:00~$endH:00 일정'),
        content: TextField(
          controller: labelCtrl, autofocus: true,
          decoration: InputDecoration(hintText: '일정 이름 입력', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, labelCtrl.text.trim()),
            child: const Text('등록', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;
    final r = Routine(id: _uuid.v4(), label: label, days: [day],
      startHour: startH, endHour: endH, startMinute: startM, endMinute: endM,
      colorIndex: _colorIndex % routineColors.length, createdAt: DateTime.now());
    await _storage.addRoutine(r);
    setState(() { _routines.add(r); _colorIndex++; });
    _showSnack('$day요일 $label 등록 완료 ✅');
  }

  // ── 직접 설정 모달 ─────────────────────────────────────────
  void _showManualInputModal() {
    const allDays = ['월','화','수','목','금','토','일'];
    final labelCtrl = TextEditingController();
    List<String> selDays = [];
    int startHour = 0, startMinute = 0, endHour = 1, endMinute = 0;
    int selColor = _colorIndex % routineColors.length;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('직접 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 14),
              TextField(controller: labelCtrl, decoration: InputDecoration(
                labelText: '일정 이름', hintText: '예: 운동, 공부',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              )),
              const SizedBox(height: 12),
              const Text('요일', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              // 모바일: 한 줄에 7개 요일 모두
              Row(
                children: allDays.map((d) {
                  final sel = selDays.contains(d);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setM(() => sel ? selDays.remove(d) : selDays.add(d)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _themeColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(d, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: sel ? Colors.white : Colors.grey[600], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // 시작 시간 (시+분)
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('시작 시간', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: startHour,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i시', style: const TextStyle(fontSize: 13)))),
                      onChanged: (v) => setM(() { startHour = v!; }),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: startMinute,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      items: [0,10,20,30,40,50].map((m) => DropdownMenuItem(value: m, child: Text('$m분', style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setM(() => startMinute = v!),
                    )),
                  ]),
                ])),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('종료 시간', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: endHour,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      items: List.generate(25, (i) => DropdownMenuItem(value: i, child: Text(i == 24 ? '익일0시' : '$i시', style: const TextStyle(fontSize: 13)))),
                      onChanged: (v) => setM(() { endHour = v!; }),
                    )),
                    const SizedBox(width: 4),
                    Expanded(child: DropdownButtonFormField<int>(
                      initialValue: endMinute,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      items: [0,10,20,30,40,50].map((m) => DropdownMenuItem(value: m, child: Text('$m분', style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setM(() => endMinute = v!),
                    )),
                  ]),
                ])),
              ]),
              const SizedBox(height: 12),
              const Text('색상', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: List.generate(routineColors.length, (i) => GestureDetector(
                onTap: () => setM(() => selColor = i),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: routineColors[i].bg, shape: BoxShape.circle,
                    border: i == selColor ? Border.all(color: Colors.black, width: 2.5) : null,
                  ),
                ),
              ))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _themeColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () async {
                    final lbl = labelCtrl.text.trim();
                    if (lbl.isEmpty || selDays.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('이름과 요일을 입력해주세요'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                      return;
                    }
                    final isCross = endHour < startHour || (endHour == startHour && endMinute <= startMinute);
                    if (isCross) {
                      // 익일 분리
                      final r1 = Routine(id: _uuid.v4(), label: lbl, days: selDays,
                        startHour: startHour, endHour: 24, startMinute: startMinute, endMinute: 0,
                        colorIndex: selColor, createdAt: DateTime.now());
                      await _storage.addRoutine(r1); _routines.add(r1); _colorIndex++;
                      final nextDays = selDays.map((d){ final idx=['월','화','수','목','금','토','일'].indexOf(d); return ['월','화','수','목','금','토','일'][(idx+1)%7]; }).toList();
                      final r2 = Routine(id: _uuid.v4(), label: lbl, days: nextDays,
                        startHour: 0, endHour: endHour, startMinute: 0, endMinute: endMinute,
                        colorIndex: selColor, createdAt: DateTime.now());
                      await _storage.addRoutine(r2); _routines.add(r2); _colorIndex++;
                    } else {
                      final r = Routine(id: _uuid.v4(), label: lbl, days: selDays,
                        startHour: startHour, endHour: endHour, startMinute: startMinute, endMinute: endMinute,
                        colorIndex: selColor, createdAt: DateTime.now());
                      await _storage.addRoutine(r); _routines.add(r); _colorIndex++;
                    }
                    setState(() {});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('일정 등록 완료 ✅');
                  },
                  child: const Text('등록하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── 수정 모달 ───────────────────────────────────────────────
  void _showEditModal(Routine r) {
    const allDays = ['월','화','수','목','금','토','일'];
    final labelCtrl = TextEditingController(text: r.label);
    int selColor = r.colorIndex;
    List<String> selDays = List.from(r.days);
    int startHour = r.startHour, startMinute = r.startMinute;
    int endHour = r.endHour, endMinute = r.endMinute;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('일정 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { _deleteRoutine(r.id); Navigator.pop(ctx); }),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 12),
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: '일정 이름', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('시작', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<int>(
                    initialValue: startHour,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i시', style: const TextStyle(fontSize: 12)))),
                    onChanged: (v) => setM(() => startHour = v!),
                  )),
                  const SizedBox(width: 4),
                  Expanded(child: DropdownButtonFormField<int>(
                    initialValue: startMinute,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    items: [0,10,20,30,40,50].map((m) => DropdownMenuItem(value: m, child: Text('$m분', style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setM(() => startMinute = v!),
                  )),
                ]),
              ])),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('종료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<int>(
                    initialValue: endHour,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    items: List.generate(25, (i) => DropdownMenuItem(value: i, child: Text(i == 24 ? '익일0시' : '$i시', style: const TextStyle(fontSize: 12)))),
                    onChanged: (v) => setM(() => endHour = v!),
                  )),
                  const SizedBox(width: 4),
                  Expanded(child: DropdownButtonFormField<int>(
                    initialValue: endMinute,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    items: [0,10,20,30,40,50].map((m) => DropdownMenuItem(value: m, child: Text('$m분', style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setM(() => endMinute = v!),
                  )),
                ]),
              ])),
            ]),
            const SizedBox(height: 10),
            const Text('요일', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(children: allDays.map((d) {
              final sel = selDays.contains(d);
              return Expanded(child: GestureDetector(
                onTap: () => setM(() => sel ? selDays.remove(d) : selDays.add(d)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: sel ? _themeColor : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[600], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              ));
            }).toList()),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: List.generate(routineColors.length, (i) => GestureDetector(
              onTap: () => setM(() => selColor = i),
              child: Container(width: 30, height: 30,
                decoration: BoxDecoration(color: routineColors[i].bg, shape: BoxShape.circle,
                  border: i == selColor ? Border.all(color: Colors.black, width: 2.5) : null)),
            ))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _themeColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  _updateRoutine(r.copyWith(
                    label: labelCtrl.text.trim().isEmpty ? r.label : labelCtrl.text.trim(),
                    days: selDays.isEmpty ? r.days : selDays,
                    startHour: startHour, startMinute: startMinute,
                    endHour: endHour, endMinute: endMinute, colorIndex: selColor,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _deleteRoutine(String id) async {
    await _storage.deleteRoutine(id);
    setState(() => _routines.removeWhere((r) => r.id == id));
  }

  Future<void> _updateRoutine(Routine updated) async {
    await _storage.updateRoutine(updated);
    setState(() {
      final i = _routines.indexWhere((r) => r.id == updated.id);
      if (i != -1) _routines[i] = updated;
    });
  }

  // ── 이미지 저장 (전체 캡처) ─────────────────────────────────
  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) { _showSnack('캡처 실패', isError: true); return; }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { _showSnack('변환 실패', isError: true); return; }
      final bytes = byteData.buffer.asUint8List();
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'dayroutine_${_viewIndex == 0 ? 'grid' : 'circle'}_$ts.png')
        ..setAttribute('target', '_blank');
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      _showSnack('이미지 저장 완료 📸');
    } catch (e) {
      _showSnack('저장 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[400] : _themeColor,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildScheduleTab(),
          CalendarScreen(routines: _routines, onTap: _showEditModal),
          TodoScreen(routines: _routines, themeColor: _themeColor),
          SettingsScreen(
            settings: _settings, routines: _routines,
            onChanged: _saveSettings, onRoutinesChanged: _replaceRoutines, onFullReset: _fullReset,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    const titles = ['시간표', '캘린더', 'To-do list', '설정'];
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(children: [
        // 로고 클릭 → 랜딩 이동
        GestureDetector(
          onTap: widget.onGoLanding,
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_themeColor, _themeColor.withAlpha(180)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            const SizedBox(width: 8),
            Text(titles[_tabIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ]),
        ),
      ]),
      actions: _tabIndex == 0 ? [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _viewBtn(0, Icons.grid_view_rounded, '격자'),
            _viewBtn(1, Icons.donut_large_rounded, '원형'),
          ]),
        ),
        IconButton(
          onPressed: _saving ? null : _saveImage,
          icon: _saving
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _themeColor))
              : Icon(Icons.download, color: _themeColor),
          tooltip: '이미지 저장',
        ),
        const SizedBox(width: 4),
      ] : null,
    );
  }

  Widget _viewBtn(int idx, IconData icon, String label) {
    final sel = _viewIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: sel ? _themeColor : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: sel ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Column(children: [
      // 입력 영역
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                onSubmitted: (_) => _addRoutine(),
                decoration: InputDecoration(
                  hintText: '예: 월~금 오후 2시 운동 / 일 오후 5시부터 익일 3시 작업',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _themeColor, width: 1.5)),
                  errorText: _errorText, errorMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showManualInputModal,
              child: Container(width: 42, height: 42,
                decoration: BoxDecoration(border: Border.all(color: _themeColor), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.tune, color: _themeColor, size: 18)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _addRoutine,
              child: Container(width: 42, height: 42,
                decoration: BoxDecoration(color: _themeColor, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 5),
          Text('요일 시간 일정을 띄어쓰기로 입력하세요. 추가 일정은 / 로 구분합니다.',
            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]),
      ),

      // 시간표 뷰
      Expanded(
        child: RepaintBoundary(
          key: _repaintKey,
          child: Container(
            color: const Color(0xFFF8F9FF),
            child: _viewIndex == 0
                ? GridViewWidget(routines: _routines, onTap: _showEditModal, fontSize: _settings.fontSize, startHour: _wakeHour)
                : CircleViewWidget(
                    routines: _routines, dayStartHour: _wakeHour,
                    circleLabel: _settings.circleLabel,
                    onDragAdd: _onDragAdd,
                    onLabelChanged: (newLabel) => _saveSettings(_settings.copyWith(circleLabel: newLabel)),
                  ),
          ),
        ),
      ),

      // 루틴 칩 목록
      if (_routines.isNotEmpty)
        Container(
          height: 80,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _routines.length,
            itemBuilder: (ctx, i) {
              final r = _routines[i];
              final color = r.customColor ?? routineColors[r.colorIndex % routineColors.length].bg;
              return GestureDetector(
                onTap: () => _showEditModal(r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withAlpha(80)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(r.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
                    ]),
                    const SizedBox(height: 2),
                    Text(r.days.join('·'), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    Text(r.timeLabel, style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                  ]),
                ),
              );
            },
          ),
        ),
    ]);
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': '시간표'},
      {'icon': Icons.calendar_month_outlined, 'label': '캘린더'},
      {'icon': Icons.check_circle_outline, 'label': 'To-do list'},
      {'icon': Icons.settings_outlined, 'label': '설정'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = _tabIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(items[i]['icon'] as IconData, size: 22, color: sel ? _themeColor : Colors.grey[400]),
                    const SizedBox(height: 2),
                    Text(items[i]['label'] as String,
                      style: TextStyle(fontSize: 9, color: sel ? _themeColor : Colors.grey[400],
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
