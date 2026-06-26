import 'package:flutter/material.dart';
import 'package:muslim/src/features/home/data/models/zikr_title.dart';
import 'package:muslim/src/features/home/presentation/components/widgets/title_card.dart';

class HomeTitlesListView extends StatelessWidget {
  final List<DbTitle> titles;
  const HomeTitlesListView({super.key, required this.titles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemBuilder: (context, index) {
        return TitleCard(dbTitle: titles[index], index: index);
      },
      itemCount: titles.length,
    );
  }
}
