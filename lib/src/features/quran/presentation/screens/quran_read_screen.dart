import 'package:flutter/material.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:quran_library/quran_library.dart';

class QuranReadScreen extends StatefulWidget {
  final int? startPage;
  final VoidCallback? onBack;

  const QuranReadScreen({super.key, this.startPage, this.onBack});

  @override
  State<QuranReadScreen> createState() => _QuranReadScreenState();
}

class _QuranReadScreenState extends State<QuranReadScreen> {
  @override
  void initState() {
    super.initState();
    _initQuran();
  }

  Future<void> _initQuran() async {
    if (widget.startPage != null) {
      QuranLibrary().jumpToPage(widget.startPage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBack?.call();
      },
      child: Theme(
        data: ThemeData(
          brightness: Theme.of(context).brightness,
          colorScheme: Theme.of(context).colorScheme,
          useMaterial3: false,
        ),
        child: QuranLibraryScreen(
          parentContext: context,
          isDark: isDark,
          appLanguageCode: Localizations.localeOf(context).languageCode,
          backgroundColor: Theme.of(context).colorScheme.surface,
          ayahSelectedBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ayahIconColor: Theme.of(context).colorScheme.primary,
          surahInfoStyle: SurahInfoStyle.defaults(isDark: isDark, context: context).copyWith(
            ayahCount: S.of(context).ayaCount,
            firstTabText: S.of(context).surahNames,
            secondTabText: S.of(context).aboutSurah,
          ),
          basmalaStyle: BasmalaStyle(
            basmalaColor: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          ayahStyle: AyahAudioStyle.defaults(isDark: isDark, context: context).copyWith(
            readersTabText: S.of(context).readers,
          ),
          topBarStyle: QuranTopBarStyle.defaults(isDark: isDark, context: context).copyWith(
            showAudioButton: true,
            showFontsButton: true,
            tabBookmarksLabel: S.of(context).favoritesContent,
            tabSearchLabel: S.of(context).search,
            tabIndexLabel: S.of(context).index,
          ),
          indexTabStyle: IndexTabStyle.defaults(isDark: isDark, context: context).copyWith(
            tabSurahsLabel: S.of(context).surahs,
            tabJozzLabel: S.of(context).juzz,
          ),
          searchTabStyle: SearchTabStyle.defaults(isDark: isDark, context: context).copyWith(
            searchHintText: S.of(context).search,
          ),
          bookmarksTabStyle: BookmarksTabStyle.defaults(isDark: isDark, context: context).copyWith(
            emptyStateText: S.of(context).noBookmarksYet,
            greenGroupText: S.of(context).greenBookmark,
            yellowGroupText: S.of(context).yellowBookmark,
            redGroupText: S.of(context).redBookmark,
          ),
          ayahMenuStyle: AyahMenuStyle.defaults(isDark: isDark, context: context).copyWith(
            copySuccessMessage: S.of(context).ayahCopied,
            showPlayAllButton: true,
          ),
          tafsirStyle: TafsirStyle.defaults(isDark: isDark, context: context).copyWith(
            tafsirName: S.of(context).tafsir,
            translateName: S.of(context).translate,
            tafsirIsEmptyNote: S.of(context).tafsirIsEmptyNote,
            footnotesName: S.of(context).footnotes,
          ),
          topBottomQuranStyle: TopBottomQuranStyle.defaults(
            isDark: isDark,
            context: context,
          ).copyWith(
            hizbName: S.of(context).hizb,
            juzName: S.of(context).juz,
            sajdaName: S.of(context).sajda,
          ),
          onPageChanged: (pageIndex) {
            // The library handles internal saving of the last page automatically.
          },
        ),
      ),
    );
  }
}
