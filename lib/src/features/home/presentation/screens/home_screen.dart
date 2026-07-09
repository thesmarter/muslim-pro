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
import 'package:muslim/src/features/home/presentation/components/pages/titles_screen.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/side_menu.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home_search/presentation/screens/search_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/showcase_tour/presentation/showcase_tour_coordinator.dart';
import 'package:muslim/src/features/tally/presentation/screens/tally_dashboard_screen.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController tabController;
  final themeCubit = sl<ThemeCubit>();
  late Brightness _brightness;
  int _currentTabIndex = 0;

  @override
  void initState() {
    tabController = TabController(vsync: this, length: appDashboardTabs.length);
    tabController.addListener(_handleTabSelection);
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
      tabController: tabController,
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

  void _handleTabSelection() {
    if (tabController.indexIsChanging || tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = tabController.index;
      });
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
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    ShowcaseTourCoordinator.instance.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            final isQuranTab =
                appDashboardTabs[arrangement[_currentTabIndex]].widget
                    is QuranReadScreen;

            return PopScope(
              canPop: _currentTabIndex == defaultIndex,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (_currentTabIndex != defaultIndex) {
                  tabController.animateTo(defaultIndex);
                }
              },
              child: Scaffold(
                body: NestedScrollView(
                  physics: const BouncingScrollPhysics(),
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    if (isQuranTab) {
                      return [];
                    }
                    return [
                      HomeAppBar(tabController: tabController),
                    ];
                  },
                  body: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: List.generate(appDashboardTabs.length, (index) {
                      final component = appDashboardTabs[state.dashboardArrangement[index]];
                      if (component.widget is QuranReadScreen) {
                        return QuranReadScreen(
                          onBack: () => tabController.animateTo(defaultIndex),
                        );
                      }
                      return component.widget;
                    }),
                  ),
                ),
                floatingActionButton: isQuranTab
                    ? null
                    : Showcase(
                        key: ShowcaseTourKeys.fabTally,
                        title: S.of(context).showcaseTourTallyFabTitle,
                        description: S.of(context).showcaseTourTallyFabDesc,
                        targetShapeBorder: const CircleBorder(),
                        child: FloatingActionButton(
                          tooltip: S.of(context).tally,
                          child: const Icon(Icons.onetwothree, size: 35),
                          onPressed: () {
                            context.push(const TallyDashboardScreen());
                          },
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
