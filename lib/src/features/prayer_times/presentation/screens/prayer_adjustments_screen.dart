import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
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
      value: state.settings.calculationMethod,
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
