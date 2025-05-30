import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/quran/presentation/components/audio_player_controls.dart';
import 'package:muslim/src/features/quran/presentation/components/reciter_selector.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class QuranAudioPlayerScreen extends StatelessWidget {
  const QuranAudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<QuranAudioCubit>()),
        BlocProvider(
          create: (context) => sl<QuranReaderCubit>()..loadReciters(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).audioPlayer),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => _showReciterSelector(context),
              icon: const Icon(Icons.person),
              tooltip: S.of(context).selectReciter,
            ),
          ],
        ),
        body: BlocBuilder<QuranAudioCubit, QuranAudioState>(
          builder: (context, audioState) {
            return Column(
              children: [
                // Current Playing Info
                Expanded(
                  flex: 2,
                  child: _buildCurrentPlayingInfo(context, audioState),
                ),

                // Audio Controls
                const AudioPlayerControls(),

                // Reciter Info
                _buildReciterInfo(context, audioState),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentPlayingInfo(BuildContext context, QuranAudioState state) {
    if (state is QuranAudioPlaying) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Surah Name
            Text(
              state.surah.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 8),

            // English Name
            Text(
              state.surah.englishName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Translation
            Text(
              state.surah.englishNameTranslation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Surah Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  context,
                  Icons.format_list_numbered,
                  '${state.surah.number}',
                  S.of(context).surahNumber,
                ),
                _buildInfoItem(
                  context,
                  Icons.article,
                  '${state.surah.numberOfAyahs}',
                  S.of(context).ayahs,
                ),
                _buildInfoItem(
                  context,
                  Icons.location_on,
                  state.surah.revelationType,
                  S.of(context).revelation,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).selectSurahToPlay,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSurahSelector(context),
            icon: const Icon(Icons.library_music),
            label: Text(S.of(context).browseSurahs),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildReciterInfo(BuildContext context, QuranAudioState state) {
    if (state is QuranAudioPlaying) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.reciter.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    state.reciter.englishName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showReciterSelector(context),
              icon: const Icon(Icons.swap_horiz),
              tooltip: S.of(context).changeReciter,
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  void _showReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ReciterSelector(),
    );
  }

  void _showSurahSelector(BuildContext context) {
    // This would show a surah selector dialog or navigate to surah list
    Navigator.of(context).pop();
  }
}
