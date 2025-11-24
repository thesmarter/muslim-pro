import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/bookmark/presentation/screens/azkar_bookmarks_screen.dart';
import 'package:muslim/src/features/bookmark/presentation/screens/titles_bookmarks_screen.dart';
import 'package:muslim/src/features/home/presentation/components/pages/titles_screen.dart';
import 'package:muslim/src/features/settings/data/models/app_component.dart';

final List<AppComponent> appDashboardTabs = [
  AppComponent(
    title: (context) => S.of(context).index,
    widget: const TitlesScreen(),
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
