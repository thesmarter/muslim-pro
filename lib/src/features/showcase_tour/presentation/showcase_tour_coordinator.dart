import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/showcase_tour/data/repository/showcase_tour_repo.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseTourKeys {
  static final welcome = GlobalKey();
  static final searchBtn = GlobalKey();
  static final azkarTab = GlobalKey();
  static final favoritesTitlesTab = GlobalKey();
  static final favoritesZikrTab = GlobalKey();
  static final quranTab = GlobalKey();
  static final prayerTab = GlobalKey();
  static final fabTally = GlobalKey();
  static final settingsBtn = GlobalKey();
  static final drawerTally = GlobalKey();
  static final drawerQuran = GlobalKey();
  static final drawerFakeHadith = GlobalKey();
  static final drawerSettings = GlobalKey();
  static final drawerMore = GlobalKey();
}

class ShowcaseTourCoordinator {
  ShowcaseTourCoordinator._();

  static final _instance = ShowcaseTourCoordinator._();
  static ShowcaseTourCoordinator get instance => _instance;

  TabController? _tabController;
  int _azkarTabIndex = 0;
  int _favoritesTitlesTabIndex = 0;
  int _favoritesZikrTabIndex = 0;
  bool _initialized = false;
  BuildContext? _appContext;

  bool get isTourCompleted => sl<ShowcaseTourRepo>().isTourCompleted;

  static final List<GlobalKey> _allKeys = [
    ShowcaseTourKeys.welcome,
    ShowcaseTourKeys.searchBtn,
    ShowcaseTourKeys.azkarTab,
    ShowcaseTourKeys.favoritesTitlesTab,
    ShowcaseTourKeys.favoritesZikrTab,
    ShowcaseTourKeys.quranTab,
    ShowcaseTourKeys.prayerTab,
    ShowcaseTourKeys.fabTally,
    ShowcaseTourKeys.settingsBtn,
    ShowcaseTourKeys.drawerTally,
    ShowcaseTourKeys.drawerQuran,
    ShowcaseTourKeys.drawerFakeHadith,
    ShowcaseTourKeys.drawerSettings,
    ShowcaseTourKeys.drawerMore,
  ];

  void initialize({
    required TabController tabController,
    required int azkarTabIndex,
    required int favoritesTitlesTabIndex,
    required int favoritesZikrTabIndex,
  }) {
    _tabController = tabController;
    _azkarTabIndex = azkarTabIndex;
    _favoritesTitlesTabIndex = favoritesTitlesTabIndex;
    _favoritesZikrTabIndex = favoritesZikrTabIndex;
    _initialized = true;
  }

  void onTourStart(int? index, GlobalKey key) {
    if (_tabController == null) return;
    if (key == ShowcaseTourKeys.azkarTab) {
      _tabController!.animateTo(_azkarTabIndex);
    } else if (key == ShowcaseTourKeys.favoritesTitlesTab) {
      _tabController!.animateTo(_favoritesTitlesTabIndex);
    } else if (key == ShowcaseTourKeys.favoritesZikrTab) {
      _tabController!.animateTo(_favoritesZikrTabIndex);
    } else if (key == ShowcaseTourKeys.quranTab || key == ShowcaseTourKeys.prayerTab) {
      // Don't switch tabs — stay on current tab so SliverAppBar stays visible
    } else if (key == ShowcaseTourKeys.settingsBtn) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _openDrawer();
      });
    }
  }

  void _openDrawer() {
    final ctx = _appContext;
    if (ctx != null && ctx.mounted) {
      ZoomDrawer.of(ctx)?.open();
    }
  }

  void _closeDrawer() {
    final ctx = _appContext;
    if (ctx != null && ctx.mounted) {
      ZoomDrawer.of(ctx)?.close();
    }
  }

  // ignore: use_setters_to_change_properties
  void setContext(BuildContext context) {
    _appContext = context;
  }

  void startTour() {
    if (!_initialized) return;
    if (isTourCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sv = ShowcaseView.get();
      if (!sv.isShowcaseRunning) {
        sv.startShowCase(_allKeys);
      }
    });
  }

  void completeTour() {
    sl<ShowcaseTourRepo>().markTourCompleted();
    final sv = ShowcaseView.get();
    if (sv.isShowcaseRunning) {
      sv.dismiss();
    }
  }

  void restartTour() {
    sl<ShowcaseTourRepo>().resetTour();
    final sv = ShowcaseView.get();
    if (sv.isShowcaseRunning) {
      sv.dismiss();
    }
    _closeDrawer();
    if (_tabController != null) {
      _tabController!.animateTo(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sv2 = ShowcaseView.get();
      if (!sv2.isShowcaseRunning) {
        sv2.startShowCase(_allKeys);
      }
    });
  }

  void dispose() {
    _tabController = null;
    _appContext = null;
    _initialized = false;
  }
}
