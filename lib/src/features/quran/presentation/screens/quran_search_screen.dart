import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/quran/presentation/components/quran_search_bar.dart';
import 'package:muslim/src/features/quran/presentation/components/search_result_card.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_reader_cubit.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuranReaderCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).searchInQuran),
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                _searchController.clear();
                context.read<QuranReaderCubit>().clearSearch();
              },
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'مسح البحث',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuranSearchBar(
                controller: _searchController,
                readOnly: false,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
              ),
            ),

            // Search Results
            Expanded(
              child: BlocBuilder<QuranReaderCubit, QuranReaderState>(
                builder: (context, state) {
                  if (state is QuranReaderSearchEmpty) {
                    return _buildEmptyState();
                  } else if (state is QuranReaderSearchLoading) {
                    return const Loading();
                  } else if (state is QuranReaderSearchResults) {
                    return _buildSearchResults(state);
                  } else if (state is QuranReaderError) {
                    return _buildErrorState(state.message);
                  }
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).searchInQuran,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).searchHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildSearchSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'الله',
      'الرحمن',
      'الصلاة',
      'الجنة',
      'النار',
      'موسى',
      'عيسى',
      'محمد',
    ];

    return Column(
      children: [
        Text(
          S.of(context).searchSuggestions,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () {
                _searchController.text = suggestion;
                _onSearchSubmitted(suggestion);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(QuranReaderSearchResults state) {
    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).noResultsFound,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${S.of(context).noResultsFor} "${state.query}"',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${state.results.length} ${S.of(context).resultsFound}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final ayah = state.results[index];
              return SearchResultCard(
                ayah: ayah,
                searchQuery: state.query,
                onTap: () => _navigateToAyah(ayah),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
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
              if (_searchController.text.isNotEmpty) {
                _onSearchSubmitted(_searchController.text);
              }
            },
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<QuranReaderCubit>().clearSearch();
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<QuranReaderCubit>().searchQuran(query.trim());
    }
  }

  void _navigateToAyah(ayah) {
    // Navigate to the specific ayah in its surah
    // This would be implemented to navigate to the surah and highlight the ayah
    Navigator.of(context).pop();
  }
}
