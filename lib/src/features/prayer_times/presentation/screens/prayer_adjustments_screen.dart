import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_bloc.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_event.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';

class PrayerAdjustmentsScreen extends StatelessWidget {
  const PrayerAdjustmentsScreen({super.key});

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
              _buildSectionTitle(context, S.of(context).calculationMethod),
              _buildCalculationMethodDropdown(context, state),
              const Divider(height: 32),
              _buildSectionTitle(context, S.of(context).adhanAudioSettings),
              _buildAdhanAudioToggle(context, state),
              _buildVolumeSlider(context, state),
              _buildMuadhinSelection(context, state),
              _buildFullAdhanTestButton(context, state),
              const Divider(height: 32),
              _buildSectionTitle(context, S.of(context).prayerNotifications),
              _buildNotificationTile(context, S.of(context).fajr, 'fajr', settings.notifications['fajr'] ?? true, state),
              _buildNotificationTile(context, S.of(context).sunrise, 'sunrise', settings.notifications['sunrise'] ?? true, state),
              _buildNotificationTile(context, S.of(context).sunriseEnd, 'sunrise_end', settings.notifications['sunrise_end'] ?? true, state),
              _buildNotificationTile(context, S.of(context).dhuhr, 'dhuhr', settings.notifications['dhuhr'] ?? true, state),
              _buildNotificationTile(context, S.of(context).asr, 'asr', settings.notifications['asr'] ?? true, state),
              _buildNotificationTile(context, S.of(context).maghrib, 'maghrib', settings.notifications['maghrib'] ?? true, state),
              _buildNotificationTile(context, S.of(context).isha, 'isha', settings.notifications['isha'] ?? true, state),
              const Divider(height: 32),
              _buildSectionTitle(context, S.of(context).prayerAdjustments),
              _buildAdjustmentTile(context, S.of(context).fajr, 'fajr', adjustments['fajr'] ?? 0, state),
              _buildAdjustmentTile(context, S.of(context).sunrise, 'sunrise', adjustments['sunrise'] ?? 0, state),
              _buildAdjustmentTile(context, S.of(context).dhuhr, 'dhuhr', adjustments['dhuhr'] ?? 0, state),
              _buildAdjustmentTile(context, S.of(context).asr, 'asr', adjustments['asr'] ?? 0, state),
              _buildAdjustmentTile(context, S.of(context).maghrib, 'maghrib', adjustments['maghrib'] ?? 0, state),
              _buildAdjustmentTile(context, S.of(context).isha, 'isha', adjustments['isha'] ?? 0, state),
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
          onChanged: (value) {
            final newSettings = state.settings.copyWith(repeatAdhan: value);
            context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
          },
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(BuildContext context, PrayerTimesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.volume_down),
          Expanded(
            child: Slider(
              value: state.settings.adhanVolume,
              onChanged: (value) {
                // Update local service volume
                AdhanAudioService().setVolume(value);
                // Update settings in state
                final newSettings = state.settings.copyWith(adhanVolume: value);
                context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
              },
            ),
          ),
          const Icon(Icons.volume_up),
        ],
      ),
    );
  }

  Widget _buildMuadhinSelection(BuildContext context, PrayerTimesState state) {
    final adhanService = AdhanAudioService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(S.of(context).chooseMuadhin, style: Theme.of(context).textTheme.bodyMedium),
        ),
        ...adhanService.muadhins.entries.map((e) {
          return StreamBuilder<String?>(
            stream: adhanService.currentMuadhinStream,
            builder: (context, muadhinSnapshot) {
              final playingMuadhinId = muadhinSnapshot.data;
              final isThisMuadhinPlaying = playingMuadhinId == e.key;
              
              return StreamBuilder<bool>(
                stream: adhanService.isPlayingStream,
                builder: (context, playingSnapshot) {
                  final isPlaying = playingSnapshot.data ?? false;
                  final showTimer = isPlaying && isThisMuadhinPlaying;

                  return ListTile(
                    title: Text(S.of(context).getValue(e.key)),
                    leading: Radio<String>(
                      value: e.key,
                      // ignore: deprecated_member_use
                      groupValue: state.settings.muadhin,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value != null) {
                          final newSettings = state.settings.copyWith(muadhin: value);
                          context.read<PrayerTimesBloc>().add(UpdatePrayerSettings(newSettings));
                        }
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTimer) ...[
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
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            onPressed: () => adhanService.previewAdhan(e.key),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildFullAdhanTestButton(BuildContext context, PrayerTimesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.playlist_play),
        label: Text(S.of(context).testFullAdhan),
        onPressed: () async {
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCalculationMethodDropdown(BuildContext context, PrayerTimesState state) {
    final methods = {
      'muslim_world_league': 'Muslim World League',
      'egyptian': 'Egyptian General Authority of Survey',
      'karachi': 'University of Islamic Sciences, Karachi',
      'umm_al_qura': 'Umm al-Qura University, Makkah',
      'dubai': 'Dubai',
      'moon_sighting_committee': 'Moon Sighting Committee',
      'north_america': 'ISNA',
      'kuwait': 'Kuwait',
      'qatar': 'Qatar',
      'singapore': 'Singapore',
      'tehran': 'Institute of Geophysics, University of Tehran',
      'turkey': 'Turkey',
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
