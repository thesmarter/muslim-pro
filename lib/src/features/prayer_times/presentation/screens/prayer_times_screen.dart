import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_bloc.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_event.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';
import 'package:muslim/src/features/prayer_times/presentation/screens/prayer_adjustments_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<PrayerTimesBloc>().add(LoadPrayerTimes());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocation();
    });
  }

  void _checkAndRequestLocation() {
    final state = context.read<PrayerTimesBloc>().state;
    if (state.settings.latitude == 0 && state.settings.longitude == 0) {
      _showPermissionExplanationDialog();
    }
  }

  void _showPermissionExplanationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).locationRequired),
        content: Text(S.of(context).locationPermissionExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PrayerTimesBloc>().add(DetectLocation());
            },
            child: Text(S.of(context).allow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerTimesBloc, PrayerTimesState>(
      listener: (context, state) {
        if (state.status == PrayerTimesStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? S.of(context).errorOccurred)),
          );
        }
      },
      child: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
        builder: (context, state) {
          if (state.status == PrayerTimesStatus.loading) {
            return const Loading();
          }

          if (state.status == PrayerTimesStatus.initial || (state.settings.latitude == 0 && state.settings.longitude == 0)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(S.of(context).locationRequired, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<PrayerTimesBloc>().add(DetectLocation());
                    },
                    icon: const Icon(Icons.my_location),
                    label: Text(S.of(context).detectLocation),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showSearchDialog(context),
                    icon: const Icon(Icons.search),
                    label: Text(S.of(context).searchLocation),
                  ),
                ],
              ),
            );
          }

          if (state.status == PrayerTimesStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? S.of(context).errorOccurred),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PrayerTimesBloc>().add(DetectLocation());
                    },
                    child: Text(S.of(context).detectLocation),
                  ),
                ],
              ),
            );
          }

          final pt = state.prayerTimes;
          if (pt == null) return const SizedBox();

          return Column(
            children: [
              _buildHeader(context, state.settings),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNextPrayerCard(context, pt),
                    const SizedBox(height: 24),
                    _buildPrayerList(context, pt),
                    const SizedBox(height: 24),
                    _buildSettingsButton(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PrayerSettings settings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).colorScheme.onPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.cityName ?? S.of(context).unknownLocation,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  settings.countryName ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha:0.8),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onPrimary),
          ),
          IconButton(
            onPressed: () {
              context.read<PrayerTimesBloc>().add(DetectLocation());
            },
            icon: Icon(Icons.my_location, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).searchLocation),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: S.of(context).enterCityName,
            prefixIcon: const Icon(Icons.location_city),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              context.read<PrayerTimesBloc>().add(SearchLocation(value));
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).close),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PrayerTimesBloc>().add(SearchLocation(controller.text));
                Navigator.pop(context);
              }
            },
            child: Text(S.of(context).search),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(BuildContext context, PrayerTimes pt) {
    final prayers = [
      (S.of(context).fajr, pt.fajr, Icons.wb_twilight),
      (S.of(context).sunrise, pt.sunrise, Icons.wb_sunny_outlined),
      (S.of(context).dhuhr, pt.dhuhr, Icons.wb_sunny),
      (S.of(context).asr, pt.asr, Icons.cloud_outlined),
      (S.of(context).maghrib, pt.maghrib, Icons.wb_twilight_outlined),
      (S.of(context).isha, pt.isha, Icons.nightlight_round),
    ];

    final currentPrayer = pt.currentPrayer();

    return Column(
      children: prayers.map((p) {
        final isCurrent = _isCurrentPrayer(currentPrayer, p.$1, context);
        return _buildPrayerRow(context, p.$1, p.$2, p.$3, isCurrent);
      }).toList(),
    );
  }

  bool _isCurrentPrayer(Prayer current, String name, BuildContext context) {
    switch (current) {
      case Prayer.fajr:
        return name == S.of(context).fajr;
      case Prayer.sunrise:
        return name == S.of(context).sunrise;
      case Prayer.dhuhr:
        return name == S.of(context).dhuhr;
      case Prayer.asr:
        return name == S.of(context).asr;
      case Prayer.maghrib:
        return name == S.of(context).maghrib;
      case Prayer.isha:
        return name == S.of(context).isha;
      default:
        return false;
    }
  }

  Widget _buildSettingsButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.push(const PrayerAdjustmentsScreen());
      },
      icon: const Icon(Icons.tune),
      label: Text(S.of(context).prayerAdjustments),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNextPrayerCard(BuildContext context, PrayerTimes pt) {
    Prayer next = pt.nextPrayer();
    DateTime? nextTime = pt.timeForPrayer(next);

    if (next == Prayer.none) {
      next = Prayer.fajr;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final state = context.read<PrayerTimesBloc>().state;
      final tomorrowPt = context.read<PrayerTimesBloc>().repo.calculatePrayerTimes(state.settings, tomorrow);
      nextTime = tomorrowPt.fajr;
    }

    final locale = Localizations.localeOf(context).languageCode;
    final timeFormat = DateFormat.jm(locale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            S.of(context).nextPrayer,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha:0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPrayerName(context, next),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 16),
          if (nextTime != null) ...[
            Text(
              timeFormat.format(nextTime.toLocal()),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            _buildCountdown(nextTime),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown(DateTime nextTime) {
    final diff = nextTime.difference(_now);
    if (diff.isNegative) return const SizedBox();

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }

  Widget _buildPrayerRow(BuildContext context, String name, DateTime time, IconData icon, bool isCurrent) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeFormat = DateFormat.jm(locale);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : Border.all(color: Theme.of(context).dividerColor.withValues(alpha:0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        trailing: Text(
          timeFormat.format(time.toLocal()),
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
            color: isCurrent ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  String _getPrayerName(BuildContext context, Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return S.of(context).fajr;
      case Prayer.sunrise:
        return S.of(context).sunrise;
      case Prayer.dhuhr:
        return S.of(context).dhuhr;
      case Prayer.asr:
        return S.of(context).asr;
      case Prayer.maghrib:
        return S.of(context).maghrib;
      case Prayer.isha:
        return S.of(context).isha;
      case Prayer.none:
        return "";
    }
  }
}
