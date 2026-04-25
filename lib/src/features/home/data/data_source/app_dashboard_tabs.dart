import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/bookmark/presentation/screens/azkar_bookmarks_screen.dart';
import 'package:muslim/src/features/bookmark/presentation/screens/titles_bookmarks_screen.dart';
import 'package:muslim/src/features/home/presentation/components/pages/titles_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:muslim/src/features/settings/data/models/app_component.dart';

final List<AppComponent> appDashboardTabs = [
  AppComponent(
    title: (context) => S.of(context).index,
    widget: const TitlesScreen(),
  ),
  AppComponent(
    title: (context) => S.of(context).prayerTimes,
    widget: const PrayerTimesScreen(),
  ),
  AppComponent(
    title: (context) => S.of(context).sourceQuran,
    widget: const QuranReadScreen(),
  ),
  AppComponent(
    title: (context) => S.of(context).favoritesContent,
    widget: const TitlesBookmarksScreen(),
  ),
  AppComponent(
    title: (context) => S.of(context).favoritesZikr,
    widget: const AzkarBookmarksScreen(),
  ),
];
