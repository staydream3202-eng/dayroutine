// todo_screen.dart v7
// - 하루 시작 / 하루 끝 버튼
// - 하루 끝 클릭 시 달성률 애니메이션 오버레이
// - 저장하고 자랑하기 (이미지 저장)
// - 하루 기준: 버튼 클릭 시간 기준, 누락 시 당일 시간표 마지막 시간 기준
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import '../models/routine.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class TodoScreen extends StatefulWidget {
  final List<Routine> routines;
  final Color themeColor;
  const TodoScreen({super.key, required this.routines, required this.themeColor});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  final _storage = StorageService();
  final _uuid = const Uuid();
  final _inputCtrl = TextEditingController();
  final _repaintKey = GlobalKey();

  List<TodoItem> _todos = [];
  bool _loading = true;
  DateTime? _dayStartTime;
  DateTime? _dayEndTime;
  bool _showAchievement = false;
  bool _savingImage = false;

  late AnimationController _achieveCtrl;
  late Animation<double> _achieveAnim;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _dateKey {
    final base = _dayStartTime ?? DateTime.now();
    return '${base.year}-${base.month.toString().padLeft(2, '0')}-${base.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _achieveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _achieveAnim = CurvedAnimation(parent: _achieveCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void didUpdateWidget(covariant TodoScreen old) {
    super.didUpdateWidget(old);
    if (old.routines != widget.routines) _syncRoutines();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _achieveCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // 하루 세션 로드
    final session = await _storage.getDaySession(_todayKey);
    if (session != null) {
      _dayStartTime = session['startTime'] != null ? DateTime.tryParse(session['startTime']) : null;
      _dayEndTime = session['endTime'] != null ? DateTime.tryParse(session['endTime']) : null;
    }

    final saved = await _storage.getTodos(_dateKey);
    final existingIds = saved.where((t) => t.isRoutineBased).map((t) => t.routineId).toSet();
    final newTodos = <TodoItem>[...saved];
    for (final r in widget.routines) {
      if (!existingIds.contains(r.id)) {
        newTodos.add(TodoItem(
          id: _uuid.v4(),
          label: '${r.label}  ${r.timeLabel}  (${r.days.join('·')})',
          isDone: false, isRoutineBased: true, routineId: r.id,
        ));
      }
    }
    setState(() { _todos = newTodos; _loading = false; });
    await _storage.saveTodos(_dateKey, newTodos);
  }

  Future<void> _syncRoutines() async {
    final existingIds = _todos.where((t) => t.isRoutineBased).map((t) => t.routineId).toSet();
    bool changed = false;
    for (final r in widget.routines) {
      if (!existingIds.contains(r.id)) {
        _todos.add(TodoItem(
          id: _uuid.v4(),
          label: '${r.label}  ${r.timeLabel}  (${r.days.join('·')})',
          isDone: false, isRoutineBased: true, routineId: r.id,
        ));
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
      await _storage.saveTodos(_dateKey, _todos);
    }
  }

  Future<void> _toggle(int idx) async {
    setState(() => _todos[idx] = _todos[idx].copyWith(isDone: !_todos[idx].isDone));
    await _storage.saveTodos(_dateKey, _todos);
  }

  Future<void> _add() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final item = TodoItem(id: _uuid.v4(), label: text, isDone: false, isRoutineBased: false);
    setState(() => _todos.add(item));
    _inputCtrl.clear();
    await _storage.saveTodos(_dateKey, _todos);
  }

  Future<void> _delete(int idx) async {
    setState(() => _todos.removeAt(idx));
    await _storage.saveTodos(_dateKey, _todos);
  }

  Future<void> _edit(int idx) async {
    final ctrl = TextEditingController(text: _todos[idx].label);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('항목 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl, autofocus: true,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onSubmitted: (_) async {
              final newLabel = ctrl.text.trim();
              if (newLabel.isNotEmpty) { setState(() => _todos[idx] = _todos[idx].copyWith(label: newLabel)); await _storage.saveTodos(_dateKey, _todos); }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          if (_todos[idx].isRoutineBased) ...[
            const SizedBox(height: 8),
            Text('* 할 일 목록에만 반영됩니다 (원래 스케줄 유지)', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final newLabel = ctrl.text.trim();
              if (newLabel.isNotEmpty) { setState(() => _todos[idx] = _todos[idx].copyWith(label: newLabel)); await _storage.saveTodos(_dateKey, _todos); }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 하루 시작 ────────────────────────────────────────────────
  Future<void> _startDay() async {
    final now = DateTime.now();
    setState(() => _dayStartTime = now);
    await _storage.saveDaySession(_todayKey, {
      'startTime': now.toIso8601String(),
      'endTime': null,
    });
  }

  // ── 하루 끝 ──────────────────────────────────────────────────
  Future<void> _endDay() async {
    final now = DateTime.now();
    // 시작 버튼 누락 시: 당일 시간표 가장 이른 시작시간을 폴백으로 사용
    final effectiveStart = _dayStartTime ?? _getFallbackStartTime();
    setState(() { _dayStartTime = effectiveStart; _dayEndTime = now; _showAchievement = true; });
    await _storage.saveDaySession(_todayKey, {
      'startTime': effectiveStart.toIso8601String(),
      'endTime': now.toIso8601String(),
    });
    _achieveCtrl.reset();
    _achieveCtrl.forward();
  }

  // 시간표 마지막 시간 기준 폴백 (당일 가장 늦게 끝나는 루틴의 시작 시간)
  DateTime _getFallbackStartTime() {
    final wdNames = ['월', '화', '수', '목', '금', '토', '일'];
    final todayWd = wdNames[DateTime.now().weekday - 1];
    final todayRoutines = widget.routines.where((r) => r.days.contains(todayWd)).toList();
    if (todayRoutines.isEmpty) return DateTime.now();
    final latest = todayRoutines.reduce((a, b) => a.endTotal > b.endTotal ? a : b);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, latest.endHour, latest.endMinute);
  }

  // ── 이미지 저장 ──────────────────────────────────────────────
  Future<void> _saveAchievementImage() async {
    if (_savingImage) return;
    setState(() => _savingImage = true);
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'dayroutine_todo_$ts.png')
        ..setAttribute('target', '_blank');
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('이미지 저장 완료 📸'),
          backgroundColor: widget.themeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        Column(children: [
          _buildHeader(),
          _buildInput(),
          const SizedBox(height: 8),
          // 하루 미시작 시 배너로 노출 (목록은 항상 표시)
          if (_dayStartTime == null) _buildStartDayBanner(),
          Expanded(child: _buildTodoList()),
          if (_dayStartTime != null && _dayEndTime == null) _buildEndDayButton(),
        ]),
        if (_showAchievement) _buildAchievementOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final wdNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final todayLabel = '${now.month}월 ${now.day}일 (${wdNames[now.weekday]})';
    final done = _todos.where((t) => t.isDone).length;
    final progress = _todos.isEmpty ? 0.0 : done / _todos.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [widget.themeColor, widget.themeColor.withAlpha(180)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: widget.themeColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(todayLabel, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$done/${_todos.length} 완료', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        if (_dayStartTime != null) ...[
          const SizedBox(height: 3),
          Text(
            '시작: ${_dayStartTime!.hour.toString().padLeft(2, '0')}:${_dayStartTime!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progress == 1.0 ? '🎉 모든 To-do list를 완료했습니다!' : '${(progress * 100).round()}% 달성',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ]),
    );
  }

  Widget _buildStartDayBanner() {
    return GestureDetector(
      onTap: _startDay,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.themeColor.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.themeColor.withAlpha(70)),
        ),
        child: Row(children: [
          Icon(Icons.play_circle_outline_rounded, color: widget.themeColor, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('하루 시작하기', style: TextStyle(fontWeight: FontWeight.bold, color: widget.themeColor, fontSize: 13)),
            Text('탭하면 오늘의 하루가 시작됩니다', style: TextStyle(fontSize: 11, color: widget.themeColor.withAlpha(160))),
          ])),
          Icon(Icons.chevron_right_rounded, color: widget.themeColor.withAlpha(150), size: 20),
        ]),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            decoration: InputDecoration(
              hintText: '새 To-do list 추가',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.themeColor, width: 1.5)),
            ),
            onSubmitted: (_) => _add(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _add,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: widget.themeColor, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  Widget _buildTodoList() {
    final pending = _todos.where((t) => !t.isDone).toList();
    final completed = _todos.where((t) => t.isDone).toList();

    if (_todos.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('✅', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('To-do list가 없습니다', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
        const SizedBox(height: 4),
        Text('루틴을 등록하면 자동으로 나타납니다', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionLabel('해야 할 일', pending.length),
          ...pending.map((item) {
            final idx = _todos.indexOf(item);
            return _TodoTile(key: ValueKey(item.id), item: item, themeColor: widget.themeColor,
              onToggle: () => _toggle(idx), onDelete: () => _delete(idx), onEdit: () => _edit(idx));
          }),
          const SizedBox(height: 12),
        ],
        if (completed.isNotEmpty) ...[
          _sectionLabel('완료한 일', completed.length),
          ...completed.map((item) {
            final idx = _todos.indexOf(item);
            return _TodoTile(key: ValueKey(item.id), item: item, themeColor: widget.themeColor,
              onToggle: () => _toggle(idx), onDelete: () => _delete(idx), onEdit: () => _edit(idx));
          }),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEndDayButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D2D2D),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: _endDay,
          icon: const Icon(Icons.nights_stay_outlined, color: Colors.white, size: 20),
          label: const Text('하루 끝', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAchievementOverlay() {
    final done = _todos.where((t) => t.isDone).length;
    final total = _todos.length;
    final progress = total == 0 ? 0.0 : done / total;
    final endTime = _dayEndTime ?? DateTime.now();
    final wdNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final dateLabel = '${endTime.month}월 ${endTime.day}일 (${wdNames[endTime.weekday]})';
    final startLabel = _dayStartTime != null
        ? '${_dayStartTime!.hour.toString().padLeft(2, '0')}:${_dayStartTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final endLabel = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    final String message;
    if (progress == 1.0) {
      message = '🎉 완벽한 하루였어요!';
    } else if (progress >= 0.7) {
      message = '👏 훌륭한 하루였어요!';
    } else if (progress >= 0.4) {
      message = '💪 잘 하셨어요!';
    } else {
      message = '🌱 내일도 파이팅!';
    }

    return Container(
      color: Colors.black.withAlpha(160),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 80),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // 달성률 카드 (이미지 저장 영역)
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(children: [
                  // 로고
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [widget.themeColor, widget.themeColor.withAlpha(180)]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Center(child: Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                    const SizedBox(width: 7),
                    const Text('데이루틴', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45)),
                  ]),
                  const SizedBox(height: 16),
                  Text(dateLabel, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  Text('$startLabel ~ $endLabel', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  const SizedBox(height: 24),

                  // 원형 달성률 애니메이션
                  AnimatedBuilder(
                    animation: _achieveAnim,
                    builder: (ctx, _) {
                      final animProgress = _achieveAnim.value * progress;
                      return SizedBox(
                        width: 160, height: 160,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox(
                            width: 160, height: 160,
                            child: CircularProgressIndicator(
                              value: animProgress,
                              strokeWidth: 14,
                              backgroundColor: Colors.grey[100],
                              valueColor: AlwaysStoppedAnimation(widget.themeColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(
                              '${(animProgress * 100).round()}%',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: widget.themeColor),
                            ),
                            Text('달성', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                          ]),
                        ]),
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('$done / $total 완료', style: TextStyle(fontSize: 14, color: Colors.grey[500])),

                  // 투두 요약
                  if (_todos.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ..._todos.take(6).map((t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Icon(
                              t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 15, color: t.isDone ? widget.themeColor : Colors.grey[300],
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: t.isDone ? Colors.grey[600] : Colors.grey[400],
                                decoration: t.isDone ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.grey[400],
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            )),
                          ]),
                        )),
                        if (_todos.length > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('외 ${_todos.length - 6}개 더', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          ),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // 저장하고 자랑하기
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _savingImage ? null : _saveAchievementImage,
                icon: _savingImage
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withAlpha(200)))
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('저장하고 자랑하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => _showAchievement = false),
                child: const Text('닫기', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }


  Widget _sectionLabel(String label, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ),
    ]),
  );
}

class _TodoTile extends StatefulWidget {
  final TodoItem item;
  final Color themeColor;
  final VoidCallback onToggle, onDelete, onEdit;
  const _TodoTile({super.key, required this.item, required this.themeColor, required this.onToggle, required this.onDelete, required this.onEdit});
  @override
  State<_TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<_TodoTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  void _handleToggle() async { await _ctrl.forward(); await _ctrl.reverse(); widget.onToggle(); }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.item.isDone;
    final isRoutine = widget.item.isRoutineBased;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDone ? Colors.grey[50] : isRoutine ? widget.themeColor.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDone ? Colors.grey[200]! : isRoutine ? widget.themeColor.withAlpha(60) : Colors.grey[200]!),
          boxShadow: isDone ? null : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: GestureDetector(
            onTap: _handleToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? widget.themeColor : Colors.transparent,
                border: Border.all(color: isDone ? widget.themeColor : Colors.grey[400]!, width: 2),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
            ),
          ),
          title: Text(widget.item.label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isDone ? Colors.grey[400] : Colors.black87,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationColor: Colors.grey[400],
          )),
          subtitle: isRoutine ? Row(children: [
            Icon(Icons.schedule, size: 11, color: widget.themeColor),
            const SizedBox(width: 3),
            Text('루틴 연동', style: TextStyle(fontSize: 10, color: widget.themeColor)),
          ]) : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: widget.onEdit, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 17, color: Colors.grey[400]))),
            GestureDetector(onTap: widget.onDelete, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 17, color: Colors.grey[400]))),
          ]),
        ),
      ),
    );
  }
}
