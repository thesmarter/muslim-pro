// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/showcase_tour/presentation/showcase_tour_coordinator.dart';
import 'package:showcaseview/showcaseview.dart';

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

        final arrangement = state.dashboardArrangement;
        final int azkarVisualIdx = arrangement.indexOf(
          appDashboardTabs.indexWhere((t) => t.id == 'index'),
        );
        final int favoritesTitlesVisualIdx = arrangement.indexOf(
          appDashboardTabs.indexWhere((t) => t.id == 'favorites_content'),
        );
        final int favoritesZikrVisualIdx = arrangement.indexOf(
          appDashboardTabs.indexWhere((t) => t.id == 'favorites_zikr'),
        );
        final int quranVisualIdx = arrangement.indexOf(
          appDashboardTabs.indexWhere((t) => t.id == 'quran'),
        );
        final int prayerVisualIdx = arrangement.indexOf(
          appDashboardTabs.indexWhere((t) => t.id == 'prayer_times'),
        );

        return SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          expandedHeight: 110,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 102, bottom: 68),
            title: Text(
              _getGreeting(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
                alignment: AlignmentDirectional.centerEnd.add(const AlignmentDirectional(-.1, -.1)),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 24),
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(
                      '﷽',
                      style: TextStyle(
                        fontSize: 44,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          leading: !state.isSearching
              ? Showcase(
                  key: ShowcaseTourKeys.welcome,
                  title: S.of(context).showcaseTourWelcomeTitle,
                  description: S.of(context).showcaseTourWelcomeDesc,
                  targetShapeBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                    ),
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
            child: arrangement.length != appDashboardTabs.length
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
                        final title = appDashboardTabs[arrangement[index]].title(context);
                        GlobalKey? showcaseKey;
                        String? sTitle;
                        String? sDesc;
                        if (index == azkarVisualIdx) {
                          showcaseKey = ShowcaseTourKeys.azkarTab;
                          sTitle = S.of(context).showcaseTourAzkar;
                          sDesc = S.of(context).showcaseTourAzkarDesc;
                        } else if (index == favoritesTitlesVisualIdx) {
                          showcaseKey = ShowcaseTourKeys.favoritesTitlesTab;
                          sTitle = S.of(context).showcaseTourFavoritesTitles;
                          sDesc = S.of(context).showcaseTourFavoritesTitlesDesc;
                        } else if (index == favoritesZikrVisualIdx) {
                          showcaseKey = ShowcaseTourKeys.favoritesZikrTab;
                          sTitle = S.of(context).showcaseTourFavoritesZikr;
                          sDesc = S.of(context).showcaseTourFavoritesZikrDesc;
                        } else if (index == quranVisualIdx) {
                          showcaseKey = ShowcaseTourKeys.quranTab;
                          sTitle = S.of(context).showcaseTourQuran;
                          sDesc = S.of(context).showcaseTourQuranDesc;
                        } else if (index == prayerVisualIdx) {
                          showcaseKey = ShowcaseTourKeys.prayerTab;
                          sTitle = S.of(context).showcaseTourPrayer;
                          sDesc = S.of(context).showcaseTourPrayerDesc;
                        }
                        return Tab(
                          child: sTitle != null
                              ? Showcase(
                                  key: showcaseKey!,
                                  title: sTitle,
                                  description: sDesc,
                                  child: Text(title),
                                )
                              : Text(title),
                        );
                      }),
                    ),
                  ),
          ),
          actions: [
            if (!state.isSearching) ...[
              Showcase(
                key: ShowcaseTourKeys.searchBtn,
                title: S.of(context).showcaseTourSearchTitle,
                description: S.of(context).showcaseTourSearchDesc,
                child: IconButton(
                  tooltip: S.of(context).search,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.read<HomeBloc>().add(
                      const HomeToggleSearchEvent(isSearching: true),
                    );
                  },
                ),
              ),
              Showcase(
                key: ShowcaseTourKeys.settingsBtn,
                title: S.of(context).showcaseTourSettings,
                description: S.of(context).showcaseTourSettingsDesc,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.vertical_split_rounded),
                  onPressed: () {
                    ZoomDrawer.of(context)?.toggle();
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
