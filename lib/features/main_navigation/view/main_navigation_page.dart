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
      extendBody: false,

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

        activeIcons: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.chat_bubble, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],
        inactiveIcons: const [
          Icon(Icons.home_outlined, color: Colors.grey),
          Icon(Icons.chat_bubble_outline, color: Colors.grey),
          Icon(Icons.person_outline, color: Colors.grey),
        ],

        color: Colors.white,
        circleColor: AppColors.primary,
        height: 60,
        circleWidth: 60,
        padding: const EdgeInsets.only(left: 0, right: 0, bottom: 20),

        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),

        shadowColor: Colors.grey.withOpacity(0.3),
        elevation: 10,
      ),
    );
  }
}
