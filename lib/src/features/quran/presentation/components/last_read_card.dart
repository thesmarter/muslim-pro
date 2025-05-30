import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class LastReadCard extends StatefulWidget {
  const LastReadCard({super.key});

  @override
  State<LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<LastReadCard> {
  @override
  void initState() {
    super.initState();
    // Load last read when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranReaderCubit>().loadLastRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranReaderCubit, QuranReaderState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).lastRead,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state is QuranReaderSurahLoaded) ...[
                Text(
                  state.surah.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.surah.englishNameTranslation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.surah.numberOfAyahs} ${S.of(context).ayahs}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to surah reading screen
                        _navigateToSurah(context, state.surah.number);
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: Text(S.of(context).continueReading),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  S.of(context).noLastRead,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).startReadingQuran,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Al-Fatiha (first surah)
                    _navigateToSurah(context, 1);
                  },
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: Text(S.of(context).startReading),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToSurah(BuildContext context, int surahNumber) {
    // This would navigate to the surah reading screen
    // For now, just load the surah
    context
        .read<QuranReaderCubit>()
        .loadSurah(surahNumber, withTranslation: true);
  }
}
