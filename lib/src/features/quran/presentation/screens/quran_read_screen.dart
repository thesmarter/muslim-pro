import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

class QuranReadScreen extends StatelessWidget {
  final int? startPage;

  const QuranReadScreen({super.key, this.startPage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (startPage != null) {
      QuranLibrary().jumpToPage(startPage!);
    }

    return Theme(
      data: Theme.of(context).copyWith(
        useMaterial3: false, // Required by quran_library
      ),
      child: QuranLibraryScreen(
        parentContext: context,
        isDark: isDark,
        withPageView: true,
        useDefaultAppBar: true,
        isShowAudioSlider: true,
        appLanguageCode: Localizations.localeOf(context).languageCode,
      ),
    );
  }
}
