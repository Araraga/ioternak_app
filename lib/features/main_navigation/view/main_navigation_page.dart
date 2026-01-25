import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

import '../../2_Dashboard/view/home_page.dart';
import '../../5_ai_chat/view/ai_assistant_page.dart';
import '../../4_profile/view/profile_page.dart';
import '../../../core/constants/app_colors.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _tabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wajib true agar menyatu
      extendBody: true,
      resizeToAvoidBottomInset: false,

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (v) {
          setState(() {
            _tabIndex = v;
          });
        },
        children: const [HomePage(), AiAssistantPage(), ProfilePage()],
      ),

      bottomNavigationBar: CircleNavBar(
        activeIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
          });
          _pageController.jumpToPage(index);
        },

        // 1. ICON AKTIF (DALAM LINGKARAN)
        // Biarkan normal, dia akan otomatis di tengah lingkaran
        activeIcons: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.chat_bubble, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],

        // 2. ICON TIDAK AKTIF (DI BAR PUTIH)
        // Gunakan Transform.translate agar naik TANPA merusak layout
        inactiveIcons: [
          Transform.translate(
            offset: const Offset(0, -10), // Minus artinya geser ke ATAS
            child: const Icon(Icons.home_outlined, color: Colors.grey),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: const Icon(Icons.person_outline, color: Colors.grey),
          ),
        ],

        color: Colors.white,
        circleColor: AppColors.primary,

        // Atur tinggi secukupnya. 70 biasanya pas.
        height: 85,
        circleWidth: 60,

        // 3. INI KUNCINYA AGAR NEMPEL KE BAWAH (LANTAI)
        // Jangan diubah, wajib zero.
        padding: EdgeInsets.zero,

        // Atur sudut lengkungan
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),

        shadowColor: Colors.grey.withOpacity(0.3),
        elevation: 10,
      ),
    );
  }
}
