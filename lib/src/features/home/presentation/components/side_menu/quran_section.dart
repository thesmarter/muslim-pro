import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/shared.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';

class QuranSection extends StatelessWidget {
  const QuranSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(MdiIcons.bookOpenPageVariant),
          title: Text(S.of(context).sourceQuran), // You can change this key
          childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ListTile(
              leading: Icon(MdiIcons.bookOpenVariant),
              title: Text(S.of(context).sourceQuran),
              onTap: () {
                context.push(const QuranReadScreen());
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(MdiIcons.bookOpenPageVariant),
              title: Text(S.of(context).endSuraAliImran),
              onTap: () {
                context.push(const QuranReadScreen(startPage: 75));
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.bookOpenPageVariant),
              title: Text(S.of(context).suraAlKahf),
              onTap: () {
                context.push(const QuranReadScreen(startPage: 293));
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.bookOpenPageVariant),
              title: Text(S.of(context).suraAsSajdah),
              onTap: () {
                context.push(const QuranReadScreen(startPage: 415));
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.bookOpenPageVariant),
              title: Text(S.of(context).suraAlMulk),
              onTap: () {
                context.push(const QuranReadScreen(startPage: 562));
              },
            ),
          ],
        ),
      ),
    );
  }
}
