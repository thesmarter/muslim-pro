import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/home/data/models/zikr_title.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/title_card.dart';
import 'package:muslim/src/features/home_search/data/models/search_for.dart';
import 'package:muslim/src/features/home_search/presentation/components/search_app_bar.dart';
import 'package:muslim/src/features/home_search/presentation/components/search_content_card.dart';
import 'package:muslim/src/features/home_search/presentation/components/search_filters_dialog.dart';
import 'package:muslim/src/features/home_search/presentation/components/search_for_bar.dart';
import 'package:muslim/src/features/home_search/presentation/components/search_result_viewer.dart';
import 'package:muslim/src/features/home_search/presentation/controller/cubit/search_cubit.dart';
import 'package:muslim/src/features/zikr_viewer/data/models/zikr_content.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Scaffold(
          body: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    const SearchAppBar(),
                    const SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [SearchForBar(), SearchFiltersButton()],
                      ),
                    ),
                  ];
                },
            body: state is! SearchLoadedState
                ? const Loading()
                : switch (state.searchFor) {
                    SearchFor.title => SearchResultViewer<DbTitle>(
                      pagingController: sl<SearchCubit>().titlePagingController,
                      itemBuilder: (context, item, index) {
                        return TitleCard(dbTitle: item);
                      },
                    ),
                    SearchFor.content => SearchResultViewer<DbContent>(
                      pagingController:
                          sl<SearchCubit>().contentPagingController,
                      itemBuilder: (context, item, index) {
                        return SearchContentCard(
                          index: index,
                          zikr: item,
                          searchText: state.searchText,
                        );
                      },
                    ),
                  },
          ),
        );
      },
    );
  }
}
