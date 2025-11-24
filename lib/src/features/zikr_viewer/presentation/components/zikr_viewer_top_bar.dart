import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/extensions/extension_object.dart';
import 'package:muslim/src/features/bookmark/presentation/components/zikr_toggle_favorite_icon_button.dart';
import 'package:muslim/src/features/zikr_viewer/data/models/zikr_content.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/components/commentary_dialog.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/controller/bloc/zikr_viewer_bloc.dart';

class ZikrViewerTopBar extends StatelessWidget {
  final DbContent dbContent;
  const ZikrViewerTopBar({super.key, required this.dbContent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: S.of(context).commentary,
              icon: Icon(MdiIcons.comment),
              onPressed: () {
                showCommentaryDialog(context: context, contentId: dbContent.id);
              },
            ),
            ZikrToggleFavoriteIconButton(dbContent: dbContent),
            IconButton(
              tooltip: S.of(context).share,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share),
              onPressed: () {
                context.read<ZikrViewerBloc>().add(
                  ZikrViewerShareZikrEvent(content: dbContent),
                );
              },
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40),
              child: Center(
                child: Text(
                  dbContent.count.toString().toArabicNumber(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
