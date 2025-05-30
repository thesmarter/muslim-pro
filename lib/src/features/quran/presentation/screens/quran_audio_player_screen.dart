import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/quran/presentation/components/audio_player_controls.dart';
import 'package:muslim/src/features/quran/presentation/components/reciter_selector.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';
import 'package:muslim/src/features/quran/presentation/screens/surah_selector_screen.dart';
import 'package:muslim/src/features/quran/data/repository/quran_repository.dart';

class QuranAudioPlayerScreen extends StatelessWidget {
  const QuranAudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).audioPlayer),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _showReciterSelector(context),
              icon: Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: S.of(context).selectReciter,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _showSurahSelector(context),
              icon: Icon(
                Icons.library_music_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'اختيار سورة',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Current Playing Info
          Expanded(
            flex: 2,
            child: _buildCurrentPlayingInfo(context, QuranAudioInitial()),
          ),

          // Audio Controls
          const AudioPlayerControls(),

          // Reciter Info
          _buildReciterInfo(context, QuranAudioInitial()),

          const SizedBox(height: 20),
        ],
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
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => sl<QuranReaderCubit>()..loadReciters(),
          ),
          BlocProvider.value(
            value: context.read<QuranAudioCubit>(),
          ),
        ],
        child: const ReciterSelector(),
      ),
    );
  }

  void _showSurahSelector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<QuranReaderCubit>()..loadSurahs(),
          child: SurahSelectorScreen(
            onSurahSelected: (surah) {
              // Get current reciter or use default
              final repository = sl<QuranRepository>();

              // Get default reciter if none selected
              final reciters = repository.getReciters();
              final defaultReciter =
                  reciters.isNotEmpty ? reciters.first : null;

              if (defaultReciter != null) {
                // Navigate back and show success message
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم اختيار ${surah.name} للتشغيل'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
