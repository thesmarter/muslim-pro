import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/components/home_appbar.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/side_menu.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home_search/presentation/screens/search_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/tally/presentation/screens/tally_dashboard_screen.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

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
  bool _showReturnButton = false;

  @override
  void initState() {
    tabController = TabController(vsync: this, length: appDashboardTabs.length);
    tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addObserver(this);
    _brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    super.initState();
  }

  void _handleTabSelection() {
    if (tabController.indexIsChanging || tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = tabController.index;
        // Reset return button visibility when switching to Quran tab
        _showReturnButton = true;
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

            final isQuranTab =
                appDashboardTabs[arrangement[_currentTabIndex]].widget
                    is QuranReadScreen;

            return Scaffold(
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isQuranTab) {
                        setState(() {
                          _showReturnButton = !_showReturnButton;
                        });
                      }
                    },
                    child: NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      floatHeaderSlivers: true,
                      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          if (!isQuranTab) HomeAppBar(tabController: tabController),
                        ];
                      },
                      body: TabBarView(
                    physics: isQuranTab
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    controller: tabController,
                    children: List.generate(appDashboardTabs.length, (index) {
                      final component = appDashboardTabs[state.dashboardArrangement[index]];
                      if (component.widget is QuranReadScreen) {
                        return QuranReadScreen(
                          onBack: () => tabController.animateTo(0),
                        );
                      }
                      return component.widget;
                    }),
                  ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: isQuranTab
                  ? null
                  : FloatingActionButton(
                      tooltip: S.of(context).tally,
                      child: Icon(MdiIcons.counter, size: 35),
                      onPressed: () {
                        context.push(const TallyDashboardScreen());
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
