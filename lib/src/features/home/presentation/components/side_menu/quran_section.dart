import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/features/fake_hadith/presentation/screens/fake_hadith_dashboard_screen.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/shared.dart';
import 'package:muslim/src/features/quran/data/models/surah_name_enum.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';

class QuranSection extends StatelessWidget {
  const QuranSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DrawerCard(
          child: ListTile(
            leading: Icon(MdiIcons.bookOpenPageVariant),
            title: Text(
              S.of(context).endSuraAliImran,
            ),
            onTap: () {
              context.push(
                const QuranReadScreen(
                  surahName: SurahNameEnum.endofAliImran,
                ),
              );
            },
          ),
        ),
        DrawerCard(
          child: ListTile(
            leading: Icon(MdiIcons.bookOpenPageVariant),
            title: Text(
              S.of(context).suraAlKahf,
            ),
            onTap: () {
              context.push(
                const QuranReadScreen(
                  surahName: SurahNameEnum.alKahf,
                ),
              );
            },
          ),
        ),
        DrawerCard(
          child: ListTile(
            leading: Icon(MdiIcons.bookOpenPageVariant),
            title: Text(S.of(context).suraAsSajdah),
            onTap: () {
              context.push(
                const QuranReadScreen(
                  surahName: SurahNameEnum.assajdah,
                ),
              );
            },
          ),
        ),
        DrawerCard(
          child: ListTile(
            leading: Icon(MdiIcons.bookOpenPageVariant),
            title: Text(S.of(context).suraAlMulk),
            onTap: () {
              context.push(
                const QuranReadScreen(
                  surahName: SurahNameEnum.alMulk,
                ),
              );
            },
          ),
        ),
        const DrawerDivider(),
        DrawerCard(
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(S.of(context).fakeHadith),
            onTap: () {
              context.push(
                const FakeHadithDashboardScreen(),
              );
            },
          ),
        ),
      ],
    );
  }
}
