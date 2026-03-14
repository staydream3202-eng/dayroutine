// settings_screen.dart v6
// - 일정 전체 초기화 버튼 + 확인 팝업
// - 취침 익일 체크박스 (0~11시 = 익일)
// - 기상시간 기준 토글 위치 이동 (수면&기상 설정 내부, 스케줄 라이브러리 상단)
// - 라이브러리 이름 수정 유지
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';
import '../models/routine.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final List<Routine> routines;
  final void Function(AppSettings) onChanged;
  final void Function(List<Routine>) onRoutinesChanged;
  final Future<void> Function() onFullReset;

  const SettingsScreen({super.key, required this.settings, required this.routines, required this.onChanged, required this.onRoutinesChanged, required this.onFullReset});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _s;
  final _days = ['월','화','수','목','금','토','일'];
  final _uuid = const Uuid();

  @override
  void initState() { super.initState(); _s = widget.settings; }
  @override
  void didUpdateWidget(covariant SettingsScreen old) {
    super.didUpdateWidget(old);
    if (old.settings != widget.settings) setState(() => _s = widget.settings);
  }

  void _emit(AppSettings s) { setState(() => _s = s); widget.onChanged(s); }
  Color get _theme => Color(int.parse(_s.themeColor));

  // ── 수면 설정 다이얼로그 ─────────────────────────────────────
  void _showSleepEditor(String day) {
    final keyDay = day == '전체' ? '월' : day;
    final current = _s.sleepByDay[keyDay] ?? SleepSchedule();
    int sleepH = current.sleepHour, wakeH = current.wakeHour;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${day == "전체" ? "전체 요일" : "$day요일"} 수면 설정', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // 취침 시간
            Row(children: [
              const SizedBox(width: 40, child: Text('취침', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Slider(
                value: sleepH.toDouble(), min: 0, max: 23, divisions: 23,
                activeColor: _theme, label: '$sleepH시',
                onChanged: (v) => setD(() => sleepH = v.round()),
              )),
              SizedBox(width: 36, child: Text('$sleepH시', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
            ]),
            const Divider(height: 16),
            // 기상 시간
            Row(children: [
              const SizedBox(width: 40, child: Text('기상', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Slider(
                value: wakeH.toDouble(), min: 0, max: 23, divisions: 23,
                activeColor: _theme, label: '$wakeH시',
                onChanged: (v) => setD(() => wakeH = v.round()),
              )),
              SizedBox(width: 36, child: Text('$wakeH시', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _theme.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Text(
                '취침 $sleepH:00  →  기상 $wakeH:00',
                style: TextStyle(color: _theme, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            if (!_s.perDaySleep) ...[
              const SizedBox(height: 8),
              Text('전체 요일에 동일하게 적용됩니다', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ]),
          actions: [
            TextButton(
              onPressed: () {
                setD(() { sleepH = 0; wakeH = 0; });
                final defaultS = SleepSchedule();
                if (_s.perDaySleep) {
                  final m = Map<String, SleepSchedule>.from(_s.sleepByDay);
                  m[keyDay] = defaultS;
                  _emit(_s.copyWith(sleepByDay: m));
                } else {
                  _emit(_s.copyWith(sleepByDay: {for (final d in _days) d: defaultS}));
                }
                Navigator.pop(ctx);
              },
              child: Text('초기화', style: TextStyle(color: Colors.grey[500])),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _theme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                final newS = SleepSchedule(sleepHour: sleepH, wakeHour: wakeH);
                if (_s.perDaySleep) {
                  final m = Map<String, SleepSchedule>.from(_s.sleepByDay);
                  m[keyDay] = newS;
                  _emit(_s.copyWith(sleepByDay: m));
                } else {
                  _emit(_s.copyWith(sleepByDay: {for (final d in _days) d: newS}));
                }
                Navigator.pop(ctx);
              },
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 일정 초기화 ─────────────────────────────────────────────
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('초기화', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Text('초기화 범위를 선택해 주세요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmResetFinal(fullReset: false);
            },
            child: const Text('현재 시간표만 초기화', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmResetFinal(fullReset: true);
            },
            child: const Text('모든 데이터 초기화', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetFinal({required bool fullReset}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('정말 초기화할까요?', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          fullReset
              ? '투두 리스트, 스케줄 라이브러리, 시간표 등\n모든 데이터가 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.'
              : '등록된 모든 시간표가 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              if (fullReset) {
                await widget.onFullReset();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('모든 데이터가 초기화되었습니다'),
                    backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
                  ));
                }
              } else {
                widget.onRoutinesChanged([]);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('시간표가 초기화되었습니다'),
                    backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('초기화', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 라이브러리 저장 ─────────────────────────────────────────
  void _saveToLibrary() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('라이브러리에 저장', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: nameCtrl, autofocus: true,
          decoration: InputDecoration(hintText: '예: 시험기간, 방학', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _theme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final item = ScheduleLibraryItem(id: _uuid.v4(), name: name,
                routinesJson: widget.routines.map((r) => r.toJson()).toList(), savedAt: DateTime.now());
              _emit(_s.copyWith(scheduleLibrary: [..._s.scheduleLibrary, item]));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('"$name" 저장 완료'), backgroundColor: _theme, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _renameLibraryItem(ScheduleLibraryItem item) {
    final ctrl = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('이름 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, autofocus: true,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _theme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              final updated = _s.scheduleLibrary.map((e) => e.id == item.id
                  ? ScheduleLibraryItem(id: e.id, name: newName, routinesJson: e.routinesJson, savedAt: e.savedAt)
                  : e).toList();
              _emit(_s.copyWith(scheduleLibrary: updated));
              Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loadFromLibrary(ScheduleLibraryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('"${item.name}" 불러오기'),
        content: const Text('현재 모든 일정이 교체됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _theme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              widget.onRoutinesChanged(item.routinesJson.map((j) => Routine.fromJson(j)).toList());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('"${item.name}" 불러오기 완료'), backgroundColor: _theme, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
            child: const Text('불러오기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 테마 색상 ──
        _sectionTitle('테마 색상'),
        Wrap(spacing: 10, runSpacing: 8, children: [
          _colorDot('0xFF667eea', const Color(0xFF667eea)),
          _colorDot('0xFF43b89c', const Color(0xFF43b89c)),
          _colorDot('0xFFe96950', const Color(0xFFe96950)),
          _colorDot('0xFFf7b731', const Color(0xFFf7b731)),
          _colorDot('0xFF6c5ce7', const Color(0xFF6c5ce7)),
          _colorDot('0xFF00b894', const Color(0xFF00b894)),
          _colorDot('0xFFe84393', const Color(0xFFe84393)),
          _colorDot('0xFF2d3436', const Color(0xFF2d3436)),
        ]),
        const SizedBox(height: 20),

        // ── 글자 크기 ──
        _sectionTitle('글자 크기'),
        Row(children: [
          const Text('A', style: TextStyle(fontSize: 11)),
          Expanded(child: Slider(value: _s.fontSize, min: 0.8, max: 1.4, divisions: 6, activeColor: _theme,
            label: '${(_s.fontSize*100).round()}%', onChanged: (v) => _emit(_s.copyWith(fontSize: v)))),
          const Text('A', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('미리보기', style: TextStyle(fontSize: 13 * _s.fontSize, fontWeight: FontWeight.w600, color: _theme)),
        ]),
        const SizedBox(height: 20),

        // ── 수면 & 기상 설정 ──
        _sectionTitle('수면 & 기상 설정'),
        Row(children: [
          Expanded(child: Text('요일별 개별 설정', style: TextStyle(fontSize: 13 * _s.fontSize, fontWeight: FontWeight.w600))),
          Switch(value: _s.perDaySleep, activeThumbColor: _theme, onChanged: (v) => _emit(_s.copyWith(perDaySleep: v))),
        ]),
        const SizedBox(height: 4),
        if (!_s.perDaySleep) _daySleepTile('전체')
        else ..._days.map((d) => _daySleepTile(d)),
        const SizedBox(height: 12),

        // ── 기상 시간 기준 시간표 토글 (수면&기상 설정 내부) ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _theme.withAlpha(10), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _theme.withAlpha(40)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('기상 시간 기준으로 시간표 시작', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _theme)),
              const SizedBox(height: 2),
              Text('OFF: 0시부터 / ON: 기상시간부터', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ])),
            Switch(value: _s.useWakeHourAsStart, activeThumbColor: _theme,
              onChanged: (v) => _emit(_s.copyWith(useWakeHourAsStart: v))),
          ]),
        ),
        const SizedBox(height: 20),

        // ── 스케줄 라이브러리 ──
        _sectionTitle('스케줄 라이브러리'),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _theme, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.save_alt, color: Colors.white, size: 16),
          label: const Text('현재 루틴 저장', style: TextStyle(color: Colors.white)),
          onPressed: widget.routines.isEmpty ? null : _saveToLibrary,
        ),
        const SizedBox(height: 10),
        if (_s.scheduleLibrary.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('저장된 라이브러리가 없습니다', style: TextStyle(color: Colors.grey[400], fontSize: 13)))
        else
          ..._s.scheduleLibrary.reversed.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: ListTile(
              leading: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _theme.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.schedule, color: _theme, size: 20)),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${item.routinesJson.length}개 루틴  ${item.savedAt.month}/${item.savedAt.day}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.edit_outlined, color: _theme, size: 18),
                  onPressed: () => _renameLibraryItem(item),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 4),
                TextButton(onPressed: () => _loadFromLibrary(item),
                  child: Text('불러오기', style: TextStyle(color: _theme, fontSize: 12))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _emit(_s.copyWith(scheduleLibrary: _s.scheduleLibrary.where((e) => e.id != item.id).toList())),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            ),
          )),
        const SizedBox(height: 20),

        // ── 일정 초기화 ──
        _sectionTitle('데이터 관리'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withAlpha(80)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title: const Text('일정 초기화', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            subtitle: Text('등록된 모든 일정 삭제', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: _confirmReset,
          ),
        ),
        const SizedBox(height: 24),
        Center(child: Text('데이루틴 v6.0  |  DayRoutine', style: TextStyle(color: Colors.grey[400], fontSize: 11))),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: TextStyle(fontSize: 15 * _s.fontSize, fontWeight: FontWeight.bold, color: _theme)),
  );

  Widget _colorDot(String key, Color color) {
    final sel = _s.themeColor == key;
    return GestureDetector(
      onTap: () => _emit(_s.copyWith(themeColor: key)),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: sel ? Border.all(color: Colors.black87, width: 3) : null,
          boxShadow: sel ? [BoxShadow(color: color.withAlpha(120), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _daySleepTile(String day) {
    final keyDay = day == '전체' ? '월' : day;
    final s = _s.sleepByDay[keyDay] ?? SleepSchedule();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(day == '전체' ? '전체 요일' : '$day요일',
        style: TextStyle(fontSize: 13 * _s.fontSize, fontWeight: FontWeight.w500)),
      subtitle: Text(
        '취침 ${s.sleepHour}:00  →  기상 ${s.wakeHour}:00',
        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
      onTap: () => _showSleepEditor(day == '전체' ? '전체' : day),
    );
  }
}
