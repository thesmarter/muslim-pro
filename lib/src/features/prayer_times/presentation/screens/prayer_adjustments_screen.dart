import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_bloc.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_event.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';

class PrayerAdjustmentsScreen extends StatefulWidget {
  const PrayerAdjustmentsScreen({super.key});

  static const MethodChannel _countdownChannel = MethodChannel('countdown_service');

  @override
  State<PrayerAdjustmentsScreen> createState() => _PrayerAdjustmentsScreenState();
}

class _PrayerAdjustmentsScreenState extends State<PrayerAdjustmentsScreen> {
  @override
  void dispose() {
    // إيقاف معاينة المؤذن فقط عند مغادرة الشاشة — لا يمس أذاناً حقيقياً.
    if (AdhanAudioService().isPreview) {
      AdhanAudioService().stopAdhan();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).prayerAdjustments),
      ),
      body: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
        builder: (context, state) {
          final settings = state.settings;
          final adjustments = settings.adjustments;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                title: S.of(context).calculationMethod,
                icon: Icons.calculate_outlined,
                initiallyExpanded: false,
                children: [
                  _buildCalculationMethodDropdown(context, state),
                ],
              ),
              _buildSection(
                context,
                title: S.of(context).adhanAudioSettings,
                icon: Icons.volume_up_outlined,
                initiallyExpanded: true,
                children: [
                  _buildAdhanAudioToggle(context, state),
                  _buildVolumeSlider(context, state),
                  _buildMuadhinSelection(context, state),
                  if (kDebugMode) _buildFullAdhanTestButton(context, state),
                  if (kDebugMode) _buildCountdownTestButton(context),
                ],
              ),
              _buildSection(
                context,
                title: S.of(context).prayerNotifications,
                icon: Icons.notifications_outlined,
                initiallyExpanded: false,
                children: [
                  _buildNotificationTile(context, S.of(context).fajr, 'fajr', settings.notifications['fajr'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).sunrise, 'sunrise', settings.notifications['sunrise'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).sunriseEnd, 'sunrise_end', settings.notifications['sunrise_end'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).dhuhr, 'dhuhr', settings.notifications['dhuhr'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).asr, 'asr', settings.notifications['asr'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).maghrib, 'maghrib', settings.notifications['maghrib'] ?? true, state),
                  _buildNotificationTile(context, S.of(context).isha, 'isha', settings.notifications['isha'] ?? true, state),
                ],
              ),
              _buildSection(
                context,
                title: S.of(context).prayerAdjustments,
                icon: Icons.tune_outlined,
                initiallyExpanded: false,
                children: [
                  _buildAdjustmentTile(context, S.of(context).fajr, 'fajr', adjustments['fajr'] ?? 0, state),
                  _buildAdjustmentTile(context, S.of(context).sunrise, 'sunrise', adjustments['sunrise'] ?? 0, state),
                  _buildAdjustmentTile(context, S.of(context).dhuhr, 'dhuhr', adjustments['dhuhr'] ?? 0, state),
                  _buildAdjustmentTile(context, S.of(context).asr, 'asr', adjustments['asr'] ?? 0, state),
                  _buildAdjustmentTile(context, S.of(context).maghrib, 'maghrib', adjustments['maghrib'] ?? 0, state),
                  _buildAdjustmentTile(context, S.of(context).isha, 'isha', adjustments['isha'] ?? 0, state),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdhanAudioToggle(BuildContext context, PrayerTimesState state) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(S.of(context).playAdhanSound),
          subtitle: Text(S.of(context).playAdhanSoundDesc),
          value: state.settings.playAdhanSound,
          onChanged: (value) {
            final newSettings = state.settings.copyWith(playAdhanSound: value);
            context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
          },
        ),
        SwitchListTile(
          title: Text(S.of(context).repeatAdhan),
          subtitle: Text(S.of(context).repeatAdhanDesc),
          value: state.settings.repeatAdhan,
          onChanged: state.settings.playAdhanSound ? (value) {
            final newSettings = state.settings.copyWith(repeatAdhan: value);
            context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
          } : null,
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(BuildContext context, PrayerTimesState state) {
    return Opacity(
      opacity: state.settings.playAdhanSound ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            const Icon(Icons.volume_down),
            Expanded(
              child: Slider(
                value: state.settings.adhanVolume,
                onChanged: state.settings.playAdhanSound ? (value) {
                  AdhanAudioService().setVolume(value);
                  final newSettings = state.settings.copyWith(adhanVolume: value);
                  context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
                } : null,
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),
      ),
    );
  }

  Widget _buildMuadhinSelection(BuildContext context, PrayerTimesState state) {
    final adhanService = AdhanAudioService();
    final soundEnabled = state.settings.playAdhanSound;

    // الاختيار يحدّث الراديو فوراً (emit فوري في الـ bloc) ويشغّل
    // معاينة 10 ثوانٍ تلقائياً. الضغط على نفس المؤذن يعيد المعاينة.
    void selectMuadhin(String muadhinId) {
      if (!soundEnabled) return;
      if (muadhinId != state.settings.muadhin) {
        final newSettings = state.settings.copyWith(muadhin: muadhinId);
        context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
      }
      adhanService.previewAdhan(muadhinId);
    }

    return Opacity(
      opacity: soundEnabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !soundEnabled,
        child: RadioGroup<String>(
          groupValue: state.settings.muadhin,
          onChanged: (value) {
            if (value != null) selectMuadhin(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(S.of(context).chooseMuadhin, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ...adhanService.muadhins.entries.map((e) {
              final isSelected = e.key == state.settings.muadhin;
              return StreamBuilder<String?>(
                stream: adhanService.currentMuadhinStream,
                builder: (context, muadhinSnapshot) {
                  final playingMuadhinId = muadhinSnapshot.data;
                  final isThisMuadhinPlaying = playingMuadhinId == e.key;

                  return StreamBuilder<bool>(
                    stream: adhanService.isPlayingStream,
                    builder: (context, playingSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;
                      final showStop = isPlaying && isThisMuadhinPlaying;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          title: Text(
                            S.of(context).getValue(e.key),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          leading: Radio<String>(
                            value: e.key,
                          ),
                          onTap: () => selectMuadhin(e.key),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showStop) ...[
                                StreamBuilder<Duration>(
                                  stream: adhanService.positionStream,
                                  builder: (context, posSnapshot) {
                                    final position = posSnapshot.data ?? Duration.zero;
                                    return StreamBuilder<Duration?>(
                                      stream: adhanService.durationStream,
                                      builder: (context, durSnapshot) {
                                        final duration = durSnapshot.data ?? Duration.zero;
                                        final progress = duration.inMilliseconds > 0
                                            ? position.inMilliseconds / duration.inMilliseconds
                                            : 0.0;
                                        return SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                                  onPressed: () => adhanService.stopAdhan(),
                                ),
                              ] else
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullAdhanTestButton(BuildContext context, PrayerTimesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.playlist_play),
        label: Text(S.of(context).testFullAdhan),
        onPressed: state.settings.playAdhanSound ? () async {
          final adhanService = AdhanAudioService();
          final muadhinId = state.settings.muadhin;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).startingFullAdhanTest)),
          );

          await adhanService.testFullAdhanSequence(muadhinId, (prayerName) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${S.of(context).playingAdhanFor}: $prayerName"),
              ),
            );
          });

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(S.of(context).testCompleted),
                content: Text(S.of(context).fullAdhanTestSuccess),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(S.of(context).ok),
                  ),
                ],
              ),
            );
          }
        }
        : null,
      ),
    );
  }

  Widget _buildCountdownTestButton(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.timer),
        label: Text(s.testCountdown),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: () async {
          final targetTime = DateTime.now().add(const Duration(minutes: 2));

          await PrayerAdjustmentsScreen._countdownChannel.invokeMethod('startCountdown', {
            'targetTimeMillis': targetTime.millisecondsSinceEpoch,
            'prayerName': s.countdownTestPrayerName,
            'title': s.countdownTestTitle,
            'city': s.countdownTestCity,
            'country': s.countdownTestCountry,
            'type': 'test',
            'header': s.countdownTestHeader,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.countdownTestStarted),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, String label, String key, bool isEnabled, PrayerTimesState state) {
    return SwitchListTile(
      title: Text(label),
      value: isEnabled,
      onChanged: (value) {
        final newNotifications = Map<String, bool>.from(state.settings.notifications);
        newNotifications[key] = value;
        final newSettings = state.settings.copyWith(notifications: newNotifications);
        context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: children,
      ),
    );
  }

  Widget _buildCalculationMethodDropdown(BuildContext context, PrayerTimesState state) {
    final s = S.of(context);
    final methods = <String, String>{
      'muslim_world_league': s.calcMethod_muslim_world_league,
      'egyptian': s.calcMethod_egyptian,
      'karachi': s.calcMethod_karachi,
      'umm_al_qura': s.calcMethod_umm_al_qura,
      'dubai': s.calcMethod_dubai,
      'moon_sighting_committee': s.calcMethod_moon_sighting_committee,
      'north_america': s.calcMethod_north_america,
      'kuwait': s.calcMethod_kuwait,
      'qatar': s.calcMethod_qatar,
      'singapore': s.calcMethod_singapore,
      'tehran': s.calcMethod_tehran,
      'turkey': s.calcMethod_turkey,
    };

    return DropdownButtonFormField<String>(
      initialValue: state.settings.calculationMethod,
      isExpanded: true,
      items: methods.entries.map((e) {
        return DropdownMenuItem(
          value: e.key,
          child: Text(e.value),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final newSettings = state.settings.copyWith(calculationMethod: value);
          context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
        }
      },
    );
  }

  Widget _buildAdjustmentTile(BuildContext context, String label, String key, int value, PrayerTimesState state) {
    return ListTile(
      title: Text(label),
      subtitle: Text('${value > 0 ? "+" : ""}$value ${S.of(context).minutes}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              final newAdjustments = Map<String, int>.from(state.settings.adjustments);
              newAdjustments[key] = (newAdjustments[key] ?? 0) - 1;
              final newSettings = state.settings.copyWith(adjustments: newAdjustments);
              context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              final newAdjustments = Map<String, int>.from(state.settings.adjustments);
              newAdjustments[key] = (newAdjustments[key] ?? 0) + 1;
              final newSettings = state.settings.copyWith(adjustments: newAdjustments);
              context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
            },
          ),
        ],
      ),
    );
  }
}
