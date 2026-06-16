import 'package:flutter/material.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/functions/open_url.dart';
import 'package:muslim/src/core/values/constant.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.of(context).aboutUs),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 15),
          ListTile(
            leading: Image.asset('assets/images/app_icon.png', scale: 3),
            title: Text(
              "${S.of(context).elmoslemProAppVersion} ${appVersionWithBuild()}",
            ),
            subtitle: Text(S.of(context).freeAdFreeAndOpenSourceApp),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.waving_hand),
            title: Text(S.of(context).prayForUsAndParents),
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories),
            title: Text(S.of(context).quranPagesFromAndroidQuran),
            onTap: () {
              openURL("https://android.quran.com/");
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(S.of(context).digitalCopyOfElmoslemPro),
            subtitle: Text(S.of(context).drSaeedBinAliBinWahf),
            onTap: () {
              openURL("https://www.alukah.net/library/0/55211/");
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(S.of(context).officialWebsite),
            subtitle: Text(S.of(context).drSaeedBinAliBinWahf),
            onTap: () {
              openURL("https://www.binwahaf.com/");
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(S.of(context).github),
            onTap: () async {
              await openURL(kOrgGithub);
            },
          ),
        ],
      ),
    );
  }
}
