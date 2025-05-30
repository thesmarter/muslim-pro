import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/quran/presentation/components/search_result_card.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class QuranFavoritesScreen extends StatelessWidget {
  const QuranFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuranReaderCubit>()..loadFavorites(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).favorites),
          elevation: 0,
        ),
        body: BlocBuilder<QuranReaderCubit, QuranReaderState>(
          builder: (context, state) {
            if (state is QuranReaderLoading) {
              return const Loading();
            } else if (state is QuranReaderFavoritesLoaded) {
              if (state.favorites.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildFavoritesList(context, state);
            } else if (state is QuranReaderError) {
              return _buildErrorState(context, state.message);
            }
            return _buildEmptyState(context);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).noFavoritesYet,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).addFavoritesHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    QuranReaderFavoritesLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${state.favorites.length} ${S.of(context).favoriteAyahs}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final ayah = state.favorites[index];
              return SearchResultCard(
                ayah: ayah,
                searchQuery: '',
                onTap: () => _navigateToAyah(context, ayah),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).error,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<QuranReaderCubit>().loadFavorites();
            },
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  void _navigateToAyah(BuildContext context, ayah) {
    // Navigate to the specific ayah in its surah
    Navigator.of(context).pop();
  }
}
