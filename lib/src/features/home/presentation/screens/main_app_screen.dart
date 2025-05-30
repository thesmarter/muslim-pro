import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/home/presentation/screens/home_screen.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/modern_bottom_nav_bar.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_main_screen.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(), // الأذكار
      MultiBlocProvider(
        // القرآن
        providers: [
          BlocProvider(create: (context) => sl<QuranReaderCubit>()),
          BlocProvider(create: (context) => sl<QuranAudioCubit>()),
        ],
        child: const QuranMainScreen(),
      ),
      const HomeScreen(), // المفضلة
      const HomeScreen(), // الإعدادات
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // المحتوى الرئيسي مع PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _screens,
          ),

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
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.9),
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
