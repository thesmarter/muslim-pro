import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/features/azkar_filters/data/models/zikr_filter.dart';
import 'package:muslim/src/features/azkar_filters/data/models/zikr_filter_list_extension.dart';
import 'package:muslim/src/features/azkar_filters/presentation/controller/cubit/azkar_filters_cubit.dart';
import 'package:muslim/src/features/bookmark/presentation/controller/bloc/bookmark_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/data/models/titles_freq_enum.dart';
import 'package:muslim/src/features/home/data/models/zikr_title.dart';
import 'package:muslim/src/features/home/data/repository/data_database_helper.dart';
import 'package:muslim/src/features/home/data/repository/hisn_db_helper.dart';
import 'package:muslim/src/features/home/data/repository/translation_db_helper.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:muslim/src/features/zikr_viewer/data/models/zikr_content.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BookmarkBloc bookmarkBloc;
  final AzkarFiltersCubit zikrFiltersCubit;
  late final StreamSubscription filterSubscription;
  late final StreamSubscription bookmarkSubscription;
  late final StreamSubscription themeSubscription;
  final AppSettingsRepo appSettingsRepo;
  final HisnDBHelper hisnDBHelper;
  final UserDataDBHelper userDataDBHelper;
  final TranslationDBHelper translationDBHelper;
  final ThemeCubit themeCubit;
  HomeBloc(
    this.bookmarkBloc,
    this.hisnDBHelper,
    this.appSettingsRepo,
    this.zikrFiltersCubit,
    this.userDataDBHelper,
    this.translationDBHelper,
    this.themeCubit,
  ) : super(HomeLoadingState()) {
    filterSubscription = zikrFiltersCubit.stream.listen(
      _onZikrFilterCubitChanged,
    );
    bookmarkSubscription = bookmarkBloc.stream.listen(_onBookmarkChanged);
    themeSubscription = themeCubit.stream.listen(_onThemeChanged);
    _initHandlers();
  }
  void _initHandlers() {
    on<HomeStartEvent>(_start);
    on<HomeToggleSearchEvent>(_toggleSearch);

    on<HomeDashboardReorderedEvent>(_onDashboardReorded);

    on<HomeToggleFilterEvent>(_onFilterToggled);
    on<HomeFiltersChangeEvent>(_filtersChanged);
    on<HomeBookmarksChangeEvent>(_bookmarkChanged);
  }

  String get _currentLanguage {
    return themeCubit.state.locale?.languageCode ?? 'ar';
  }

  String? _lastLocaleLanguage;

  void _onThemeChanged(ThemeState themeState) {
    final newLang = themeState.locale?.languageCode;
    if (newLang != null && _lastLocaleLanguage != null && _lastLocaleLanguage != newLang) {
      add(const HomeStartEvent());
    }
    _lastLocaleLanguage = newLang;
  }

  List<DbTitle> _applyTitleTranslations(
    List<DbTitle> titles,
    Map<int, String> translations,
  ) {
    return titles.map((title) {
      final translatedName = translations[title.id];
      if (translatedName != null) {
        return title.copyWith(nameEn: translatedName);
      }
      return title;
    }).toList();
  }

  List<DbContent> _applyContentTranslations(
    List<DbContent> contents,
    Map<int, Map<String, String?>> translations,
  ) {
    return contents.map((content) {
      final translation = translations[content.id];
      if (translation != null) {
        return content.copyWith(
          contentTranslation: translation['content'],
          transliteration: translation['transliteration'],
          fadlTranslation: translation['fadl'],
        );
      }
      return content;
    }).toList();
  }

  Future<void> _start(HomeStartEvent event, Emitter<HomeState> emit) async {
    _lastLocaleLanguage = themeCubit.state.locale?.languageCode ?? 'ar';
    final filters = zikrFiltersCubit.state.filters;
    final language = _currentLanguage;

    final dbTitles = await hisnDBHelper.getAllTitles();
    final titleTranslations =
        await translationDBHelper.getAllTitleTranslations(language);
    final translatedTitles = _applyTitleTranslations(dbTitles, titleTranslations);

    final List<DbTitle> filtered = await applyFiltersOnTitels(
      translatedTitles,
      zikrFilters: filters,
    );

    final listDbContentFavourite = await userDataDBHelper.getFavouriteContents();
    final azkarFromDB = await hisnDBHelper.getContentsByIds(
      ids: listDbContentFavourite.map((e) => e.itemId).toList(),
    );
    final contentTranslations =
        await translationDBHelper.getAllContentTranslations(language);
    final translatedAzkar = _applyContentTranslations(azkarFromDB, contentTranslations);
    final filteredAzkar = filters.getFilteredZikr(translatedAzkar);
    final bookmarkedTitlesIds = await userDataDBHelper.getAllFavoriteTitles();

    final arrangement = appSettingsRepo.getDashboardArrangement(appDashboardTabs.length);
    
    emit(
      HomeLoadedState(
        titles: filtered,
        bookmarkedContents: filteredAzkar,
        isSearching: false,
        dashboardArrangement: arrangement,
        freqFilters: appSettingsRepo.getTitlesFreqFilterStatus,
        bookmarkedTitlesIds: bookmarkedTitlesIds,
      ),
    );
  }

  Future<void> _toggleSearch(
    HomeToggleSearchEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    emit(state.copyWith(isSearching: event.isSearching));
  }

  Future<void> _onDashboardReorded(
    HomeDashboardReorderedEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    final List<int> listToSet = List<int>.from(state.dashboardArrangement);

    int newIndex = event.newIndex;

    if (event.oldIndex < newIndex) {
      newIndex -= 1;
    }
    final int item = listToSet.removeAt(event.oldIndex);
    listToSet.insert(newIndex, item);

    appSettingsRepo.changeDashboardArrangement(listToSet);

    emit(state.copyWith(dashboardArrangement: listToSet));
  }

  @override
  Future<void> close() {
    filterSubscription.cancel();
    bookmarkSubscription.cancel();
    themeSubscription.cancel();
    return super.close();
  }

  Future<void> _onFilterToggled(
    HomeToggleFilterEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    /// Handle freq change
    final List<TitlesFreqEnum> newFreq = List.of(state.freqFilters);
    if (newFreq.contains(event.filter)) {
      newFreq.remove(event.filter);
    } else {
      newFreq.add(event.filter);
    }

    await appSettingsRepo.setTitlesFreqFilterStatus(newFreq);

    emit(state.copyWith(freqFilters: newFreq));
  }

  Future<List<DbTitle>> applyFiltersOnTitels(
    List<DbTitle> titles, {
    List<Filter>? zikrFilters,
  }) async {
    final List<DbTitle> titlesToSet = [];

    final List<Filter> filters = zikrFilters ?? zikrFiltersCubit.state.filters;
    for (var i = 0; i < titles.length; i++) {
      final title = titles[i];
      final azkarFromDB = await hisnDBHelper.getContentsByTitleId(
        titleId: title.id,
      );
      final azkarToSet = filters.getFilteredZikr(azkarFromDB);
      if (azkarToSet.isNotEmpty) titlesToSet.add(title);
    }

    return titlesToSet;
  }

  Future<void> _onZikrFilterCubitChanged(AzkarFiltersState state) async {
    add(HomeFiltersChangeEvent(state.filters));
  }

  Future<void> _filtersChanged(
    HomeFiltersChangeEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    final language = _currentLanguage;

    final dbTitles = await hisnDBHelper.getAllTitles();
    final titleTranslations =
        await translationDBHelper.getAllTitleTranslations(language);
    final translatedTitles = _applyTitleTranslations(dbTitles, titleTranslations);
    final List<DbTitle> filtered = await applyFiltersOnTitels(
      translatedTitles,
      zikrFilters: event.filters,
    );

    final listDbContentFavourite = await userDataDBHelper.getFavouriteContents();
    final azkarFromDB = await hisnDBHelper.getContentsByIds(
      ids: listDbContentFavourite.map((e) => e.itemId).toList(),
    );
    final contentTranslations =
        await translationDBHelper.getAllContentTranslations(language);
    final translatedAzkar = _applyContentTranslations(azkarFromDB, contentTranslations);

    final filteredAzkar = event.filters.getFilteredZikr(translatedAzkar);

    emit(state.copyWith(titles: filtered, bookmarkedContents: filteredAzkar));
  }

  void _onBookmarkChanged(BookmarkState bState) {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    final bookmarkState = bState;
    if (bookmarkState is! BookmarkLoadedState) return;

    add(
      HomeBookmarksChangeEvent(
        bookmarkedTitlesIds: bookmarkState.bookmarkedTitlesIds,
        bookmarkedContents: bookmarkState.bookmarkedContents,
      ),
    );
  }

  Future<void> _bookmarkChanged(
    HomeBookmarksChangeEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state;
    if (state is! HomeLoadedState) return;

    emit(
      state.copyWith(
        bookmarkedTitlesIds: List.of(event.bookmarkedTitlesIds),
        bookmarkedContents: List.of(event.bookmarkedContents),
      ),
    );
  }
}
