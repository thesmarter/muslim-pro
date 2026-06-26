// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';

class HomeAppBar extends StatelessWidget {
  final TabController tabController;
  const HomeAppBar({super.key, required this.tabController});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return hour < 12 ? 'صباح الخير ☀️' : 'مساء الخير 🌙';
    } else if (locale == 'fr') {
      return hour < 12 ? 'Bonjour ☀️' : 'Bonsoir 🌙';
    } else if (locale == 'tr') {
      return hour < 12 ? 'Günaydın ☀️' : 'İyi akşamlar 🌙';
    }
    return hour < 12 ? 'Good Morning ☀️' : 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const SizedBox();
        }
        return SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 72, bottom: 48),
            title: Text(
              _getGreeting(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 24),
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      '﷽',
                      style: TextStyle(
                        fontSize: 48,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          leading: !state.isSearching
              ? Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                )
              : IconButton(
                  tooltip: S.of(context).close,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.read<HomeBloc>().add(
                      const HomeToggleSearchEvent(isSearching: false),
                    );
                  },
                ),
          bottom: PreferredSize(
            preferredSize: const Size(0, 48),
            child: state.dashboardArrangement.length != appDashboardTabs.length
                ? const SizedBox()
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: TabBar(
                      controller: tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                      tabs: List.generate(appDashboardTabs.length, (index) {
                        return Tab(
                          child: Text(
                            appDashboardTabs[state.dashboardArrangement[index]].title(
                              context,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
          ),
          actions: [
            if (!state.isSearching) ...[
              IconButton(
                tooltip: S.of(context).search,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.search),
                onPressed: () {
                  context.read<HomeBloc>().add(
                    const HomeToggleSearchEvent(isSearching: true),
                  );
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.vertical_split_rounded),
                onPressed: () {
                  ZoomDrawer.of(context)?.toggle();
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
