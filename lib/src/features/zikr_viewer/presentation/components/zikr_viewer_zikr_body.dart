// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/core/shared/widgets/text_divider.dart';
import 'package:muslim/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:muslim/src/features/zikr_viewer/data/models/zikr_content.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/components/zikr_content_builder.dart';

class ZikrViewerZikrBody extends StatelessWidget {
  final DbContent dbContent;
  const ZikrViewerZikrBody({
    super.key,
    required this.dbContent,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final bool showTranslation = locale != 'ar';
    final bool hasTranslation = showTranslation &&
        dbContent.contentTranslation != null &&
        dbContent.contentTranslation!.isNotEmpty;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (hasTranslation) {
          return _buildBilingualContent(context, state);
        }

        return _buildOriginalContent(context, state);
      },
    );
  }

  Widget _buildBilingualContent(BuildContext context, SettingsState state) {
    final double baseFontSize = state.fontSize * 10;
    final double smallerFontSize = baseFontSize * 0.85;
    final bool enableDiacritics = state.showDiacritics;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dbContent.transliteration != null &&
            dbContent.transliteration!.isNotEmpty) ...[
          Text(
            dbContent.transliteration!,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            softWrap: true,
            style: TextStyle(
              fontSize: smallerFontSize * 0.8,
              fontStyle: FontStyle.italic,
              height: 1.8,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          dbContent.contentTranslation!,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          softWrap: true,
          style: TextStyle(
            fontSize: smallerFontSize,
            height: 1.8,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        ZikrContentBuilder(
          dbContent: dbContent,
          enableDiacritics: enableDiacritics,
          fontSize: baseFontSize,
        ),
        if (dbContent.fadl.isNotEmpty) ...[
          const SizedBox(height: 20),
          const TextDivider(),
          Text(
            (dbContent.fadlTranslation != null &&
                    dbContent.fadlTranslation!.isNotEmpty)
                ? dbContent.fadlTranslation!
                : dbContent.fadl,
            textAlign: TextAlign.center,
            textDirection: (dbContent.fadlTranslation != null &&
                    dbContent.fadlTranslation!.isNotEmpty)
                ? TextDirection.ltr
                : TextDirection.rtl,
            softWrap: true,
            style: TextStyle(
              fontSize: state.fontSize * 8,
              height: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOriginalContent(BuildContext context, SettingsState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZikrContentBuilder(
          dbContent: dbContent,
          enableDiacritics: state.showDiacritics,
          fontSize: state.fontSize * 10,
        ),
        if (dbContent.fadl.isNotEmpty) ...[
          const SizedBox(height: 20),
          const TextDivider(),
          Text(
            dbContent.fadl,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            softWrap: true,
            style: TextStyle(
              fontSize: state.fontSize * 8,
              height: 2,
            ),
          ),
        ],
      ],
    );
  }
}
