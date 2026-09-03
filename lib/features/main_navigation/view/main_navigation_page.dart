import 'dart:ui';
import 'package:flutter/material.dart';

import '../../2_Dashboard/view/home_page.dart';
import '../../5_kandang_management/view/kandang_management_page.dart';
import '../../4_profile/view/profile_page.dart';
import '../../5_ai_chat/view/ai_assistant_page.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/navigation_tab_switcher.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  late PageController _pageController;
  late AnimationController _navAnimController;

  final List<_NavItem> _navItems = [
    _NavItem(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Beranda',
    ),
    _NavItem(
      activeIcon: Icons.article_rounded,
      inactiveIcon: Icons.article_outlined,
      label: 'Kandang',
    ),
    _NavItem(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    // Daftarkan callback agar HomePage bisa switch tab tanpa circular import
    NavigationTabSwitcher.switchTab = (index) => _onTabTap(index);
  }

  @override
  void dispose() {
    NavigationTabSwitcher.switchTab = null;
    _pageController.dispose();
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    _pageController.jumpToPage(index);
    _navAnimController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (v) => setState(() => _tabIndex = v),
        children: const [
          HomePage(),
          KandangManagementPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(bottomPad),
    );
  }

  Widget _buildNavBar(double bottomPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Pill nav (Home, Kandang, Profile) ──
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.65),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _navItems.length,
                      (i) => _buildNavItem(i),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── AI Button — bintang 4 sudut Gemini style ──
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiAssistantPage(),
                ),
              );
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1ABC9C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF1ABC9C).withOpacity(0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset('assets/icon/navai.png', width: 28, height: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = _tabIndex == index;

    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isActive ? item.activeIcon : item.inactiveIcon,
            key: ValueKey(isActive),
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    this.label = '',
  });
}

/// Custom painter untuk bintang 4 sudut (logo Gemini style)
class _GeminiStarPainter extends CustomPainter {
  final Color color;
  const _GeminiStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Bintang 4 sudut (Gemini style) = 4 lengkung diamond
    final path = Path();

    // Titik-titik bintang 4 sudut
    // Top point
    final topX = cx;
    final topY = cy - r;
    // Right point
    final rightX = cx + r;
    final rightY = cy;
    // Bottom point
    final bottomX = cx;
    final bottomY = cy + r;
    // Left point
    final leftX = cx - r;
    final leftY = cy;

    // Control points (inner curve — membuat efek "squircle star")
    final cInner = r * 0.25;

    path.moveTo(topX, topY);
    // Top → Right
    path.cubicTo(
      cx + cInner, cy - r + cInner,
      cx + r - cInner, cy - cInner,
      rightX, rightY,
    );
    // Right → Bottom
    path.cubicTo(
      cx + r - cInner, cy + cInner,
      cx + cInner, cy + r - cInner,
      bottomX, bottomY,
    );
    // Bottom → Left
    path.cubicTo(
      cx - cInner, cy + r - cInner,
      cx - r + cInner, cy + cInner,
      leftX, leftY,
    );
    // Left → Top
    path.cubicTo(
      cx - r + cInner, cy - cInner,
      cx - cInner, cy - r + cInner,
      topX, topY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
