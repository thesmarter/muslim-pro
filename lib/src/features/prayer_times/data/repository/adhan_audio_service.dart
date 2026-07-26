
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/prayer_times/data/repository/prayer_times_repo.dart';
import 'package:rxdart/rxdart.dart';

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  static const MethodChannel _adhanChannel = MethodChannel('adhan_scheduler');

  final _player = AudioPlayer();
  String? _currentPlayingMuadhinId;
  String? get currentPlayingMuadhinId => _currentPlayingMuadhinId;

  bool _isInitialized = false;
  StreamSubscription<ProcessingState>? _stateSubscription;

  final _currentMuadhinSubject = BehaviorSubject<String?>();
  Stream<String?> get currentMuadhinStream => _currentMuadhinSubject.stream;

  bool get isPlaying => _player.playing;
  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  final Map<String, String> muadhins = {
    'siddiq_hamdoun': 'assets/sounds/azhan/siddiq_hamdoun.mp3',
    'abdul_basit': 'assets/sounds/azhan/abdul_basit.mp3',
    'farooq_hadrawi': 'assets/sounds/azhan/farooq_hadrawi.mp3',
    'noreen_mohammed': 'assets/sounds/azhan/noreen_mohammed.mp3',
    'wadie_alyamani': 'assets/sounds/azhan/wadie_alyamani.mp3',
    'yasser_alhouri': 'assets/sounds/azhan/yasser_alhouri.mp3',
  };

  Future<void> init() async {
    if (_isInitialized) {
      hisnPrint("Adhan audio player already initialized");
      return;
    }

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.alarm,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);

    await _stateSubscription?.cancel();

    _stateSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        final settings = sl<PrayerTimesRepo>().getSettings();
        if (settings.repeatAdhan) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          stopAdhan();
        }
      }
    });

    try {
      final settings = sl<PrayerTimesRepo>().getSettings();
      await _player.setVolume(settings.adhanVolume);
      hisnPrint("Initial Adhan volume set to: ${settings.adhanVolume}");
    } catch (e) {
      hisnPrint("Error setting initial volume: $e");
    }

    _isInitialized = true;
    hisnPrint("Adhan audio player initialized");
  }

  bool _isLoading = false;

  Future<void> playAdhan(String muadhinId) async {
    if (_isLoading) {
      hisnPrint("Playback request ignored: Already loading an asset");
      return;
    }

    try {
      _isLoading = true;
      hisnPrint("playAdhan requested for: $muadhinId");
      final soundPath = muadhins[muadhinId] ?? muadhins['wadie_alyamani']!;
      hisnPrint("Resolved sound path: $soundPath");

      if (_player.playing || _player.processingState != ProcessingState.idle) {
        hisnPrint("Stopping current playback/loading before new request");
        await _player.stop();
      }

      _currentPlayingMuadhinId = muadhinId;
      _currentMuadhinSubject.add(muadhinId);

      hisnPrint("Setting asset: $soundPath");
      await _player.setAsset(soundPath);

      final settings = sl<PrayerTimesRepo>().getSettings();
      await _player.setVolume(settings.adhanVolume);
      hisnPrint("Volume confirmed at: ${settings.adhanVolume}");

      hisnPrint("Starting playback");
      await _player.play();

      hisnPrint("Successfully playing Adhan: $muadhinId");
    } on PlayerException catch (e) {
      _currentPlayingMuadhinId = null;
      _currentMuadhinSubject.add(null);
      hisnPrint("PlayerException ($muadhinId): ${e.code} - ${e.message}");
      if (muadhinId != 'wadie_alyamani') {
        hisnPrint("Attempting fallback to default muadhin...");
        _isLoading = false;
        await playAdhan('wadie_alyamani');
      }
    } on PlayerInterruptedException catch (e) {
      _currentPlayingMuadhinId = null;
      _currentMuadhinSubject.add(null);
      hisnPrint("Connection interrupted: ${e.message}");
    } catch (e) {
      _currentPlayingMuadhinId = null;
      _currentMuadhinSubject.add(null);
      hisnPrint("Unexpected error playing adhan: $e");
    } finally {
      _isLoading = false;
    }
  }

  Future<void> stopAdhan() async {
    try {
      if (_player.processingState != ProcessingState.idle) {
        await _player.stop();
      }
      _currentPlayingMuadhinId = null;
      _currentMuadhinSubject.add(null);
      hisnPrint("Adhan stopped");
    } catch (e) {
      hisnPrint("Error stopping adhan: $e");
    }
    await stopNativeAdhan();
  }

  Future<void> previewAdhan(String muadhinId) async {
    await stopAdhan();
    await playAdhan(muadhinId);
    Future.delayed(const Duration(seconds: 10), () {
      if (_player.playing) {
        stopAdhan();
      }
    });
  }

  Future<void> testFullAdhanSequence(String muadhinId, Function(String prayerName) onPrayerChange) async {
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    try {
      hisnPrint("--- Starting Full Adhan Test Sequence ---");

      if (_player.volume == 0) {
        setVolume(0.5);
      }

      for (final prayerKey in prayers) {
        final prayerName = SX.current.getValue(prayerKey);
        onPrayerChange(prayerName);

        hisnPrint("Testing Adhan for: $prayerName");

        await sl<LocalNotificationManager>().showAdhanNotification(
          id: 990 + prayers.indexOf(prayerKey),
          title: "اختبار الأذان: $prayerName",
          body: "اختبار صوت الأذان والإشعار",
          payload: "test_adhan_$muadhinId",
          soundFileName: muadhinId,
          muadhinId: muadhinId,
        );

        await Future.delayed(const Duration(seconds: 5));
        await stopAdhan();
      }
      hisnPrint("--- Full Adhan Test Sequence Completed Successfully ---");
    } catch (e) {
      hisnPrint("Error during full adhan test: $e");
    }
  }

  void setVolume(double volume) {
    _player.setVolume(volume);
  }

  void dispose() {
    _stateSubscription?.cancel();
    _player.dispose();
    _currentMuadhinSubject.close();
    _isInitialized = false;
  }

  // ─── Native Foreground Service Control ───

  Future<void> scheduleAdhanAlarm({
    required String muadhin,
    required String prayerName,
    required DateTime time,
    required double volume,
    required int id,
    required bool playSound,
  }) async {
    try {
      await _adhanChannel.invokeMethod('schedule', {
        'muadhin': muadhin,
        'prayerName': prayerName,
        'timestamp': time.millisecondsSinceEpoch,
        'volume': volume,
        'id': id,
        'playSound': playSound,
      });
    } catch (e) {
      hisnPrint('Error scheduling adhan alarm: $e');
    }
  }

  Future<void> cancelAdhanAlarm(int id) async {
    try {
      await _adhanChannel.invokeMethod('cancel', id);
    } catch (e) {
      hisnPrint('Error canceling adhan alarm: $e');
    }
  }

  Future<void> cancelAllAdhanAlarms() async {
    try {
      await _adhanChannel.invokeMethod('cancelAll');
    } catch (e) {
      hisnPrint('Error canceling all adhan alarms: $e');
    }
  }

  Future<void> stopNativeAdhan() async {
    try {
      await _adhanChannel.invokeMethod('stopAdhan');
    } catch (e) {
      hisnPrint('Error stopping native adhan: $e');
    }
  }
}
