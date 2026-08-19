import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/components/home_appbar.dart';
import 'package:muslim/src/features/home/presentation/components/muslim_bottom_nav_bar.dart';
import 'package:muslim/src/features/home/presentation/components/pages/titles_screen.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/side_menu.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home_search/presentation/screens/search_screen.dart';
import 'package:muslim/src/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/showcase_tour/presentation/showcase_tour_coordinator.dart';
import 'package:muslim/src/features/tally/presentation/screens/tally_dashboard_screen.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:showcaseview/showcaseview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const Loading();
        }
        return Scaffold(
          body: ZoomDrawer(
            isRtl: Bidi.isRtlLanguage(
              Localizations.localeOf(context).languageCode,
            ),
            menuBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
            menuScreen: const SideMenu(),
            mainScreen: const DashboardScreen(),
            borderRadius: 24.0,
            showShadow: true,
            angle: 0.0,
            drawerShadowsBackgroundColor: Theme.of(context).colorScheme.primary,
            slideWidth: 270,
          ),
        );
      },
    );
  }
}

class _TabWithAppBar extends StatelessWidget {
  final Widget child;
  const _TabWithAppBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      physics: const BouncingScrollPhysics(),
      floatHeaderSlivers: true,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [const HomeAppBar()];
      },
      body: child,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late final PersistentTabController _navController;
  final themeCubit = sl<ThemeCubit>();
  late Brightness _brightness;

  @override
  void initState() {
    _navController = PersistentTabController();
    WidgetsBinding.instance.addObserver(this);
    _brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    super.initState();

    ShowcaseView.register(
      overlayColor: Colors.black,
      overlayOpacity: 0.6,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 500),
      skipIfTargetNotPresent: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initShowcaseTour();
      }
    });
  }

  void _initShowcaseTour() {
    final arrangement =
        (context.read<HomeBloc>().state as HomeLoadedState).dashboardArrangement;

    final int azkarTabIdx = arrangement.indexOf(
      appDashboardTabs.indexWhere((t) => t.id == 'index'),
    );
    final int favoritesTitlesTabIdx = arrangement.indexOf(
      appDashboardTabs.indexWhere((t) => t.id == 'favorites_content'),
    );
    final int favoritesZikrTabIdx = arrangement.indexOf(
      appDashboardTabs.indexWhere((t) => t.id == 'favorites_zikr'),
    );
    ShowcaseTourCoordinator.instance.initialize(
      persistentNavController: _navController,
      azkarTabIndex: azkarTabIdx >= 0 ? azkarTabIdx : 0,
      favoritesTitlesTabIndex: favoritesTitlesTabIdx >= 0 ? favoritesTitlesTabIdx : 0,
      favoritesZikrTabIndex: favoritesZikrTabIdx >= 0 ? favoritesZikrTabIdx : 0,
    );
    ShowcaseTourCoordinator.instance.setContext(context);

    final sv = ShowcaseView.get();
    sv.addOnStartCallback((index, key) {
      ShowcaseTourCoordinator.instance.onTourStart(index, key);
    });
    sv.addOnFinishCallback(() {
      ShowcaseTourCoordinator.instance.completeTour();
    });

    if (!ShowcaseTourCoordinator.instance.isTourCompleted) {
      ShowcaseTourCoordinator.instance.startTour();
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_brightness != brightness) {
      sl<ThemeCubit>().changeDeviceBrightness(brightness);
      _brightness = brightness;
    }
  }

  @override
  void dispose() {
    _navController.dispose();
    ShowcaseTourCoordinator.instance.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<PersistentTabConfig> _buildTabs(List<int> arrangement) {
    final colorScheme = Theme.of(context).colorScheme;

    final icons = [
      Icons.menu_book_rounded,
      Icons.favorite_rounded,
      Icons.star_rounded,
      Icons.auto_stories_rounded,
      Icons.access_time_rounded,
    ];

    final inactiveIcons = [
      Icons.menu_book_outlined,
      Icons.favorite_outline_rounded,
      Icons.star_outline_rounded,
      Icons.auto_stories_outlined,
      Icons.access_time_outlined,
    ];

    return List.generate(appDashboardTabs.length, (index) {
      final component = appDashboardTabs[arrangement[index]];
      final isQuranTab = component.widget is QuranReadScreen;
      final isPrayerTab = component.widget is PrayerTimesScreen;

      Widget screen;
      if (isQuranTab) {
        screen = QuranReadScreen(
          onBack: () => _navController.jumpToTab(0),
        );
      } else if (isPrayerTab) {
        screen = const PrayerTimesScreen();
      } else {
        screen = _TabWithAppBar(child: component.widget);
      }

      return PersistentTabConfig(
        screen: screen,
        item: ItemConfig(
          icon: Icon(icons[index]),
          inactiveIcon: Icon(inactiveIcons[index]),
          title: component.title(context),
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          activeForegroundColor: colorScheme.primary,
          inactiveForegroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    });
  }

  bool _isFabVisible(List<int> arrangement) {
    final selectedIndex = _navController.index;
    if (selectedIndex < 0 || selectedIndex >= arrangement.length) return true;
    final component = appDashboardTabs[arrangement[selectedIndex]];
    return component.widget is! QuranReadScreen &&
        component.widget is! PrayerTimesScreen;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AlarmsBloc, AlarmsState>(
      builder: (context, state) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is! HomeLoadedState) {
              return const Loading();
            }
            if (state.isSearching) {
              return const SearchScreen();
            }

            final arrangement = state.dashboardArrangement;
            if (arrangement.length != appDashboardTabs.length) {
              return const Loading();
            }

            final int mainTabIndex = arrangement.indexWhere(
              (idx) => appDashboardTabs[idx].widget is TitlesScreen,
            );
            final int defaultIndex = mainTabIndex != -1 ? mainTabIndex : 0;

            return PopScope(
              canPop: _navController.index == defaultIndex,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (_navController.index != defaultIndex) {
                  _navController.jumpToTab(defaultIndex);
                }
              },
              child: PersistentTabView(
                controller: _navController,
                tabs: _buildTabs(arrangement),
                navBarBuilder: (navBarConfig) => MuslimBottomNavBar(
                  navBarConfig: navBarConfig,
                ),
                hideOnScrollVelocity: 10,
                backgroundColor: colorScheme.surface,
                floatingActionButton: AnimatedBuilder(
                  animation: _navController,
                  builder: (context, child) {
                    final isFabVisible = _isFabVisible(arrangement);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isFabVisible
                          ? Showcase(
                              key: ShowcaseTourKeys.fabTally,
                              title: S.of(context).showcaseTourTallyFabTitle,
                              description:
                                  S.of(context).showcaseTourTallyFabDesc,
                              targetShapeBorder: const CircleBorder(),
                              child: FloatingActionButton(
                                tooltip: S.of(context).tally,
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                child: const Icon(Icons.onetwothree, size: 35),
                                onPressed: () {
                                  context.push(const TallyDashboardScreen());
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
