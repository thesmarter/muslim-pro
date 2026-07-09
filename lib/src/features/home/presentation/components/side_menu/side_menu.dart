import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/features/fake_hadith/presentation/screens/fake_hadith_dashboard_screen.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/footer_section.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/header_section.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/more_section.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/quran_section.dart';
import 'package:muslim/src/features/home/presentation/components/side_menu/shared.dart';
import 'package:muslim/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:muslim/src/features/showcase_tour/presentation/showcase_tour_coordinator.dart';
import 'package:muslim/src/features/tally/presentation/screens/tally_dashboard_screen.dart';
import 'package:showcaseview/showcaseview.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeaderSection(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      Showcase(
                        key: ShowcaseTourKeys.drawerTally,
                        title: S.of(context).showcaseTourDrawerTallyTitle,
                        description: S.of(context).showcaseTourDrawerTallyDesc,
                        child: Material(
                          type: MaterialType.transparency,
                          child: DrawerCard(
                            child: ListTile(
                              leading: const Icon(Icons.onetwothree),
                              title: Text(S.of(context).tally),
                              onTap: () {
                                context.push(const TallyDashboardScreen());
                              },
                            ),
                          ),
                        ),
                      ),
                      const DrawerDivider(),
                      Showcase(
                        key: ShowcaseTourKeys.drawerQuran,
                        title: S.of(context).showcaseTourDrawerQuranTitle,
                        description: S.of(context).showcaseTourDrawerQuranDesc,
                        child: const QuranSection(),
                      ),
                      const DrawerDivider(),
                      Showcase(
                        key: ShowcaseTourKeys.drawerFakeHadith,
                        title: S.of(context).showcaseTourDrawerFakeHadithTitle,
                        description: S.of(context).showcaseTourDrawerFakeHadithDesc,
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(S.of(context).fakeHadith),
                            onTap: () {
                              context.push(const FakeHadithDashboardScreen());
                            },
                          ),
                        ),
                      ),
                      const DrawerDivider(),
                      Showcase(
                        key: ShowcaseTourKeys.drawerSettings,
                        title: S.of(context).showcaseTourDrawerSettingsTitle,
                        description: S.of(context).showcaseTourDrawerSettingsDesc,
                        child: Material(
                          type: MaterialType.transparency,
                          child: DrawerCard(
                            child: ListTile(
                              leading: const Icon(Icons.settings),
                              title: Text(S.of(context).settings),
                              onTap: () {
                                context.push(const SettingsScreen());
                              },
                            ),
                          ),
                        ),
                      ),
                      const DrawerDivider(),
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: const Icon(Icons.tour_rounded),
                          title: Text(S.of(context).restartShowcaseTour),
                          onTap: () {
                            ZoomDrawer.of(context)?.close();
                            ShowcaseTourCoordinator.instance.restartTour();
                          },
                        ),
                      ),
                      const DrawerDivider(),
                      Showcase(
                        key: ShowcaseTourKeys.drawerMore,
                        title: S.of(context).showcaseTourDrawerMoreTitle,
                        description: S.of(context).showcaseTourDrawerMoreDesc,
                        child: const MoreSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FooterSection(),
        ],
      ),
    );
  }
}
