import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class ReciterSelector extends StatelessWidget {
  const ReciterSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            S.of(context).selectReciter,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Reciters List
          Expanded(
            child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
              builder: (context, state) {
                if (state is QuranReaderRecitersLoaded) {
                  return ListView.builder(
                    itemCount: state.reciters.length,
                    itemBuilder: (context, index) {
                      final reciter = state.reciters[index];
                      return _ReciterCard(
                        reciter: reciter,
                        onTap: () => _selectReciter(context, reciter),
                      );
                    },
                  );
                }

                // Fallback to default reciters
                const defaultReciters = PopularReciters.reciters;
                return ListView.builder(
                  itemCount: defaultReciters.length,
                  itemBuilder: (context, index) {
                    final reciter = defaultReciters[index];
                    return _ReciterCard(
                      reciter: reciter,
                      onTap: () => _selectReciter(context, reciter),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectReciter(BuildContext context, Reciter reciter) {
    // Update the selected reciter
    context.read<QuranReaderCubit>().selectReciter(reciter);

    // If audio is currently playing, change the reciter
    final audioState = context.read<QuranAudioCubit>().state;
    if (audioState is QuranAudioPlaying) {
      context.read<QuranAudioCubit>().changeReciter(reciter);
    }

    Navigator.of(context).pop();
  }
}

class _ReciterCard extends StatelessWidget {
  final Reciter reciter;
  final VoidCallback onTap;

  const _ReciterCard({
    required this.reciter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: reciter.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: reciter.isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: reciter.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: reciter.imageUrl != null
                    ? NetworkImage(reciter.imageUrl!)
                    : null,
                child: reciter.imageUrl == null
                    ? Icon(
                        Icons.person,
                        color: reciter.isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // Reciter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic Name
                    Text(
                      reciter.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: reciter.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                      textDirection: TextDirection.rtl,
                    ),

                    const SizedBox(height: 4),

                    // English Name
                    Text(
                      reciter.englishName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),

                    // Description
                    if (reciter.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        reciter.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Selection Indicator
              if (reciter.isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
