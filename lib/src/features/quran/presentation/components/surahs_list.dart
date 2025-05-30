import 'package:flutter/material.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/presentation/components/surah_card.dart';

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
    // Navigate to surah reading screen
    // This would be implemented to navigate to the detailed surah view
    Navigator.of(context).pushNamed(
      '/quran/surah',
      arguments: surah.number,
    );
  }
}
