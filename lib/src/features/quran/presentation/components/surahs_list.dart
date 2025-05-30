import 'package:flutter/material.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/presentation/components/surah_card.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_reader_screen.dart';

class SurahsList extends StatelessWidget {
  final List<Surah> surahs;

  const SurahsList({
    super.key,
    required this.surahs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return SurahCard(
          surah: surah,
          onTap: () => _navigateToSurah(context, surah),
        );
      },
    );
  }

  void _navigateToSurah(BuildContext context, Surah surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(surahNumber: surah.number),
      ),
    );
  }
}
