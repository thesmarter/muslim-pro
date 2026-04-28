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

    return Theme(
      data: ThemeData(
        brightness: Theme.of(context).brightness,
        colorScheme: Theme.of(context).colorScheme,
        useMaterial3: false,
      ),
      child: QuranLibraryScreen(
        parentContext: context,
        isDark: isDark,
        appBar: widget.onBack != null
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                title: Text(S.of(context).sourceQuran),
                centerTitle: true,
              )
            : null,
        appLanguageCode: Localizations.localeOf(context).languageCode,
        topBarStyle: QuranTopBarStyle.defaults(isDark: isDark, context: context).copyWith(
          showAudioButton: true,
          showFontsButton: true,
          tabBookmarksLabel: S.of(context).favoritesContent,
          tabSearchLabel: S.of(context).search,
          tabIndexLabel: S.of(context).index,
        ),
        bookmarksTabStyle: BookmarksTabStyle.defaults(isDark: isDark, context: context).copyWith(
          emptyStateText: S.of(context).nothingFoundInFavorites,
        ),
        onPageChanged: (pageIndex) {
          // The library handles internal saving of the last page automatically.
        },
      ),
    );
  }
}
