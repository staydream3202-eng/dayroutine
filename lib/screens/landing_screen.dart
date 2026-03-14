// landing_screen.dart v6
// - 우측 상단 시작하기 버튼 제거
// - 하단 기능카드 박스 제거
// - To-do 워딩 통일: 'To-do list'
// - 모바일 반응형 개선
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onStart;
  const LandingScreen({super.key, required this.onStart});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) { _fadeCtrl.forward(); _slideCtrl.forward(); }
    });
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _slideCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isMobile = w < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(children: [
          // ── 헤더 (로고만, 시작하기 버튼 없음) ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 14),
            child: Row(children: [
              GestureDetector(
                onTap: widget.onStart,
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  ),
                  const SizedBox(width: 8),
                  const Text('데이루틴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                ]),
              ),
            ]),
          ),

          // ── 히어로 카드 (화면 중앙, 전체 공간 사용) ──
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : w * 0.15,
                    vertical: isMobile ? 12 : 24,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxHeight: h * 0.78),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
                      boxShadow: [BoxShadow(color: const Color(0xFF667eea).withAlpha(90), blurRadius: 32, offset: const Offset(0, 14))],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 28 : 52),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '로그인 없이 시작하는\n나만의 시간표 & 루틴관리',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 26 : 42,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: isMobile ? 10 : 16),
                          Text(
                            '입력만으로 편리하게 시간표 완성',
                            style: TextStyle(
                              color: Colors.white.withAlpha(210),
                              fontSize: isMobile ? 14 : 20,
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 32),
                          // 배지 2x2 그리드
                          const Column(
                            children: [
                              Row(children: [
                                Expanded(child: _Badge(icon: '💾', text: '시간표 저장')),
                                SizedBox(width: 8),
                                Expanded(child: _Badge(icon: '✅', text: 'To-do list')),
                              ]),
                              SizedBox(height: 8),
                              Row(children: [
                                Expanded(child: _Badge(icon: '⌨️', text: '편리한 입력')),
                                SizedBox(width: 8),
                                Expanded(child: _Badge(icon: '🌙', text: '야간 루틴')),
                              ]),
                            ],
                          ),
                          SizedBox(height: isMobile ? 24 : 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onStart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667eea),
                                padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                '지금 시작하기 →',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              '화면을 나가도 내 기기에 자동 저장됩니다',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon, text;
  const _Badge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(35),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withAlpha(80)),
    ),
    child: Text('$icon $text', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
