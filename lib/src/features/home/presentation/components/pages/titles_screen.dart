import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/shared/widgets/empty.dart';
import 'package:muslim/src/features/home/presentation/components/pages/titles_list_view.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/titles_freq_filters_card.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/themes/data/models/app_colors.dart';

class TitlesScreen extends StatelessWidget {
  const TitlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const SizedBox();
        }
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: state.titles.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Empty(
                    isImage: false,
                    icon: Icons.menu_book_rounded,
                    title: S.of(context).noTitleWithName,
                    description: S.of(context).reviewIndexOfBook,
                  ),
                )
              : Column(
                  children: [
                    // Modern Filter Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const TitleFreqFilterCard(),
                    ),
                    // Modern List View
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: HomeTitlesListView(
                          titles: state.allTitles,
                          alarms: state.alarms,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
