// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/features/alarms_manager/presentation/components/title_card_alarm_button.dart';
import 'package:muslim/src/features/bookmark/presentation/components/bookmark_title_button.dart';
import 'package:muslim/src/features/home/data/models/zikr_title.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/screens/zikr_viewer_screen.dart';

class TitleCard extends StatelessWidget {
  final DbTitle dbTitle;
  final int index;

  const TitleCard({super.key, required this.dbTitle, this.index = 0});

  static const _cardColors = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
    Color(0xFFFFF3E0),
    Color(0xFFE0F7FA),
    Color(0xFFFCE4EC),
    Color(0xFFF1F8E9),
    Color(0xFFEDE7F6),
  ];

  static const _cardDarkColors = [
    Color(0xFF1B3A1D),
    Color(0xFF1A2A3A),
    Color(0xFF2A1A2D),
    Color(0xFF3A2A1A),
    Color(0xFF1A3A3A),
    Color(0xFF3A1A2A),
    Color(0xFF1A2A1A),
    Color(0xFF2A1A3A),
  ];

  static const _accentColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF8BC34A),
    Color(0xFF673AB7),
  ];

  static const _icons = [
    Icons.wb_sunny_outlined,
    Icons.nightlight_round,
    Icons.bedtime_outlined,
    Icons.alarm_outlined,
    Icons.book_outlined,
    Icons.auto_stories,
    Icons.menu_book_outlined,
    Icons.chrome_reader_mode_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorIndex = index % _cardColors.length;
    final cardColor = isDark ? _cardDarkColors[colorIndex] : _cardColors[colorIndex];
    final accentColor = _accentColors[colorIndex];
    final icon = _icons[colorIndex];

    final displayName = dbTitle.nameEn != null && dbTitle.nameEn!.isNotEmpty
        ? dbTitle.nameEn!
        : dbTitle.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(ZikrViewerScreen(index: dbTitle.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dbTitle.order}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                BookmarkTitleButton(titleId: dbTitle.id),
                const SizedBox(width: 4),
                TitleCardAlarmButton(dbTitle: dbTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
