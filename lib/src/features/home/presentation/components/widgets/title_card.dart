import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/core/extensions/extension_platform.dart';
import 'package:muslim/src/core/models/editor_result.dart';
import 'package:muslim/src/features/alarms_manager/data/models/alarm.dart';
import 'package:muslim/src/features/alarms_manager/presentation/components/alarm_editor.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/models/zikr_title.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/screens/zikr_viewer_screen.dart';

class TitleCard extends StatelessWidget {
  final Color? titleColor;
  final DbTitle dbTitle;
  final DbAlarm? dbAlarm;

  const TitleCard({
    super.key,
    required this.dbTitle,
    required this.dbAlarm,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final DbAlarm alarm =
        dbAlarm ?? DbAlarm(titleId: dbTitle.id, title: dbTitle.name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              ZikrViewerScreen(index: dbTitle.id),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: titleColor ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Order Number
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      dbTitle.order.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title and Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dbTitle.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط للمتابعة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bookmark Button
                    Container(
                      decoration: BoxDecoration(
                        color: dbTitle.favourite
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: IconButton(
                        tooltip: S.of(context).bookmark,
                        icon: Icon(
                          dbTitle.favourite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_add_outlined,
                          color: dbTitle.favourite
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          sl<HomeBloc>().add(
                            HomeToggleTitleBookmarkEvent(
                              title: dbTitle,
                              bookmark: !dbTitle.favourite,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Alarm Button
                    if (!PlatformExtension.isDesktop)
                      Container(
                        decoration: BoxDecoration(
                          color: (dbAlarm?.isActive ?? false)
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: _TitleCardAlarmButton(
                            alarm: alarm, dbAlarm: dbAlarm),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleCardAlarmButton extends StatelessWidget {
  final DbAlarm alarm;
  final DbAlarm? dbAlarm;
  const _TitleCardAlarmButton({required this.alarm, this.dbAlarm});

  @override
  Widget build(BuildContext context) {
    return dbAlarm == null
        ? IconButton(
            icon: const Icon(Icons.alarm_add_rounded),
            onPressed: () async {
              final EditorResult<DbAlarm>? result = await showAlarmEditorDialog(
                context: context,
                dbAlarm: alarm,
                isToEdit: false,
              );

              if (result == null) return;
              if (!context.mounted) return;

              context.read<AlarmsBloc>().add(AlarmsAddEvent(result.value));
            },
          )
        : GestureDetector(
            onLongPress: () async {
              final EditorResult<DbAlarm>? result = await showAlarmEditorDialog(
                context: context,
                dbAlarm: alarm,
                isToEdit: true,
              );

              if (result == null) return;
              if (!context.mounted) return;
              switch (result.action) {
                case EditorActionEnum.edit:
                  context.read<AlarmsBloc>().add(AlarmsEditEvent(result.value));
                case EditorActionEnum.delete:
                  context
                      .read<AlarmsBloc>()
                      .add(AlarmsRemoveEvent(result.value));
                default:
              }
            },
            child: alarm.isActive
                ? IconButton(
                    icon: Icon(
                      Icons.notifications_active_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<AlarmsBloc>().add(
                            AlarmsEditEvent(
                              alarm.copyWith(isActive: false),
                            ),
                          );
                    },
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.notifications_off,
                    ),
                    onPressed: () {
                      context.read<AlarmsBloc>().add(
                            AlarmsEditEvent(
                              alarm.copyWith(isActive: true),
                            ),
                          );
                    },
                  ),
          );
  }
}
