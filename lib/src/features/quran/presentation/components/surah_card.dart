import 'package:flutter/material.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Surah Number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    surah.number.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Surah Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic Name
                    Text(
                      surah.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                      textDirection: TextDirection.rtl,
                    ),

                    const SizedBox(height: 4),

                    // English Name
                    Text(
                      surah.englishName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),

                    const SizedBox(height: 2),

                    // Translation
                    Text(
                      surah.englishNameTranslation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),

              // Surah Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Revelation Type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRevelationTypeColor(
                        context,
                        surah.revelationType,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRevelationTypeText(context, surah.revelationType),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Number of Ayahs
                  Text(
                    '${surah.numberOfAyahs} ${S.of(context).ayahs}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),

                  const SizedBox(height: 4),

                  // Favorite Icon
                  if (surah.isFavorite)
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                ],
              ),

              const SizedBox(width: 8),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRevelationTypeColor(BuildContext context, String revelationType) {
    switch (revelationType.toLowerCase()) {
      case 'meccan':
        return Theme.of(context).colorScheme.primary;
      case 'medinan':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _getRevelationTypeText(BuildContext context, String revelationType) {
    switch (revelationType.toLowerCase()) {
      case 'meccan':
        return S.of(context).meccan;
      case 'medinan':
        return S.of(context).medinan;
      default:
        return revelationType;
    }
  }
}
