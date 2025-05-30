import 'package:flutter/material.dart';
import 'package:muslim/src/features/home/presentation/screens/home_screen.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/modern_bottom_nav_bar.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(), // الأذكار
    const HomeScreen(), // القرآن (سيتم تحديثه لاحقاً)
    const HomeScreen(), // المفضلة
    const HomeScreen(), // الإعدادات
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // التنقل حسب الفهرس
    switch (index) {
      case 0:
        // الأذكار - البقاء في الشاشة الحالية
        break;
      case 1:
        // القرآن
        Navigator.of(context).pushNamed('/quran');
        break;
      case 2:
        // المفضلة - تبديل إلى تاب المفضلة
        break;
      case 3:
        // الإعدادات
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // المحتوى الرئيسي
          const HomeScreen(),
          
          // شريط التنقل السفلي
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: SafeArea(
                child: HomeBottomNavBar(
                  currentTabIndex: _currentIndex,
                  onTabChanged: _onTabChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
