import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/shared/widgets/empty.dart';
import 'package:muslim/src/features/home/presentation/components/pages/titles_list_view.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/titles_freq_filters_card.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';

class TitlesScreen extends StatelessWidget {
  const TitlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoadedState) {
          return const SizedBox();
        }
        return state.titles.isEmpty
            ? Empty(
                isImage: false,
                icon: Icons.search_outlined,
                title: S.of(context).noTitleWithName,
                description: S.of(context).reviewIndexOfBook,
              )
            : Column(
                children: [
                  const TitleFreqFilterCard(),
                  Expanded(child: HomeTitlesListView(titles: state.allTitles)),
                ],
              );
      },
    );
  }
}
