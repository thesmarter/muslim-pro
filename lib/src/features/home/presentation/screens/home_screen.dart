import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/components/home_appbar.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/side_menu.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home_search/presentation/controller/cubit/search_cubit.dart';
import 'package:muslim/src/features/home_search/presentation/screens/home_search_screen.dart';
import 'package:muslim/src/features/themes/data/models/app_colors.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/modern_bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const Loading();
        }
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: ZoomDrawer(
              isRtl: Bidi.isRtlLanguage(
                Localizations.localeOf(context).languageCode,
              ),
              controller: sl<HomeBloc>().zoomDrawerController,
              menuBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              menuScreen: const SideMenu(),
              mainScreen: const DashboardScreen(),
              borderRadius: 28.0,
              showShadow: true,
              angle: 0.0,
              drawerShadowsBackgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              slideWidth: 280,
              mainScreenScale: 0.15,
              menuScreenWidth: 280,
            ),
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
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  @override
  void initState() {
    tabController = TabController(vsync: this, length: appDashboardTabs.length);
    super.initState();
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
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: NestedScrollView(
                  physics: const BouncingScrollPhysics(),
                  floatHeaderSlivers: true,
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      HomeAppBar(tabController: tabController),
                    ];
                  },
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.isSearching &
                            context
                                .watch<SearchCubit>()
                                .state
                                .searchText
                                .isNotEmpty
                        ? const HomeSearchScreen()
                        : TabBarView(
                            physics: const BouncingScrollPhysics(),
                            controller: tabController,
                            children: List.generate(
                              appDashboardTabs.length,
                              (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: appDashboardTabs[
                                          state.dashboardArrangement[index]]
                                      .widget,
                                );
                              },
                            ),
                          ),
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
