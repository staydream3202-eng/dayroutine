import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/parse_input.dart';
import '../widgets/grid_view_widget.dart';
import '../widgets/circle_view_widget.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _routineService = RoutineService();
  final _authService = AuthService();
  final _inputController = TextEditingController();
  int _viewIndex = 0;
  int _colorIndex = 0;
  String? _errorText;

  void _addRoutine() {
    final parsed = parseInput(_inputController.text.trim());
    if (parsed == null) {
      setState(() => _errorText = '예: 월화수 9시-12시 영어공부');
      return;
    }
    final routine = Routine(
      id: '',
      label: parsed.label,
      days: parsed.days,
      startHour: parsed.startHour,
      endHour: parsed.endHour,
      colorIndex: _colorIndex % routineColors.length,
      createdAt: DateTime.now(),
    );
    _routineService.addRoutine(widget.user.uid, routine);
    setState(() {
      _colorIndex++;
      _errorText = null;
      _inputController.clear();
    });
  }

  void _showEditModal(Routine r) {
    final ctrl = TextEditingController(text: r.label);
    int selectedColor = r.colorIndex;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('루틴 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: '루틴 이름',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('색상 선택',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(routineColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: routineColors[i].bg,
                        shape: BoxShape.circle,
                        border: i == selectedColor
                            ? Border.all(color: Colors.black, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _routineService.updateRoutine(
                          widget.user.uid,
                          Routine(
                            id: r.id,
                            label: ctrl.text,
                            days: r.days,
                            startHour: r.startHour,
                            endHour: r.endHour,
                            colorIndex: selectedColor,
                            createdAt: r.createdAt,
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('저장',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _routineService.deleteRoutine(widget.user.uid, r.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text('삭제',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('🗓', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Text('데이루틴',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _authService.signOut(),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: widget.user.photoURL != null
                            ? NetworkImage(widget.user.photoURL!)
                            : null,
                        child: widget.user.photoURL == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    onSubmitted: (_) => _addRoutine(),
                                    decoration: InputDecoration(
                                      hintText: '월화수 9시-12시 영어공부',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF667eea),
                                              width: 2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667eea),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: _addRoutine,
                                  child: const Text('추가',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            if (_errorText != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 6, left: 4),
                                child: Text(_errorText!,
                                    style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 11)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                '예: 평일 9시-18시 업무  /  주말 10시-12시 취미',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            _tabButton('📋 격자형', 0),
                            const SizedBox(width: 8),
                            _tabButton('⭕ 원형', 1),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Routine>>(
                          stream:
                              _routineService.getRoutines(widget.user.uid),
                          builder: (ctx, snap) {
                            final routines = snap.data ?? [];
                            if (routines.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('✨',
                                        style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
                                    Text('첫 루틴을 추가해보세요!',
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 16)),
                                  ],
                                ),
                              );
                            }
                            return _viewIndex == 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: GridViewWidget(
                                        routines: routines,
                                        onTap: _showEditModal),
                                  )
                                : CircleViewWidget(routines: routines);
                          },
                        ),
                      ),
                      StreamBuilder<List<Routine>>(
                        stream: _routineService.getRoutines(widget.user.uid),
                        builder: (ctx, snap) {
                          final routines = snap.data ?? [];
                          if (routines.isEmpty) return const SizedBox();
                          return Container(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: Colors.grey[200]!)),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: routines.map((r) {
                                final c = routineColors[
                                    r.colorIndex % routineColors.length];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: c.light,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: c.bg,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 5),
                                      Text(r.label,
                                          style: TextStyle(
                                              color: c.text,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _routineService
                                            .deleteRoutine(
                                                widget.user.uid, r.id),
                                        child: Text('×',
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)])
              : null,
          color: selected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}