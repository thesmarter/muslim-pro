import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:quran_library/quran_library.dart';

/// Central coordinator for app-wide audio behavior.
///
/// Solves two systemic problems:
/// 1. The Quran playback session (owned by `quran_library`/`audio_service`)
///    wakes up on any headset/Bluetooth media-button press, even when the app
///    is closed. Since the library hardcodes its service config, routing is
///    controlled here by enabling/disabling the manifest-merged
///    `MediaButtonReceiver` at runtime.
/// 2. The adhan player configures the process-wide [AudioSession] singleton
///    with the alarm stream; without scoping, `just_audio` propagates that
///    configuration to the Quran player. The Quran player is therefore pinned
///    back to the media stream at every key moment.
class AppAudioCoordinator with WidgetsBindingObserver {
  static const MethodChannel _routingChannel = MethodChannel('audio_routing');

  bool _initialized = false;
  bool _quranScreenVisible = false;
  bool _quranPlaying = false;
  bool _appInBackground = false;
  StreamSubscription<bool>? _quranPlayingSub;

  /// Pure routing policy — unit testable.
  ///
  /// Media buttons stay enabled while recitation is playing (so the user can
  /// pause from headset/Bluetooth) or while the Quran screen is in the
  /// foreground. They are disabled otherwise so a press can never wake the
  /// recitation up from the background.
  static bool shouldEnableMediaButtons({
    required bool quranPlaying,
    required bool quranScreenVisible,
    required bool appInBackground,
  }) {
    return quranPlaying || (quranScreenVisible && !appInBackground);
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    // Start locked down: no wake-ups until the Quran UI is actually open.
    await pinQuranToMedia();
    try {
      final quranPlayer = AudioCtrl.instance.state.audioPlayer;
      _quranPlaying = quranPlayer.playing;
      _quranPlayingSub = quranPlayer.playingStream.listen((playing) {
        final wasPlaying = _quranPlaying;
        _quranPlaying = playing;
        if (playing && !wasPlaying) {
          _onQuranPlaybackStarted();
        }
        _refreshMediaButtonRouting();
      });
    } catch (e) {
      hisnPrint('AppAudioCoordinator: quran player hook failed: $e');
    }
    await _refreshMediaButtonRouting();
  }

  /// Called by the Quran screen on show/hide.
  void setQuranScreenVisible(bool visible) {
    _quranScreenVisible = visible;
    if (visible) {
      pinQuranToMedia();
    }
    _refreshMediaButtonRouting();
  }

  /// Pins the Quran recitation player to the media stream explicitly so a
  /// previous adhan alarm configuration can never leak into it.
  Future<void> pinQuranToMedia() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await AudioCtrl.instance.state.audioPlayer.setAndroidAudioAttributes(
        const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
      );
    } catch (e) {
      hisnPrint('AppAudioCoordinator: pin quran to media failed: $e');
    }
  }

  void _onQuranPlaybackStarted() {
    // Mutual exclusion: a recitation starting stops an adhan preview.
    // Real native adhan alarms are untouched — the Dart player is idle then.
    try {
      final adhan = sl<AdhanAudioService>();
      if (adhan.isPlaying) {
        adhan.stopAdhan();
      }
    } catch (_) {}
    pinQuranToMedia();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInBackground = state != AppLifecycleState.resumed;
    _refreshMediaButtonRouting();
  }

  Future<void> _refreshMediaButtonRouting() async {
    if (!Platform.isAndroid) return;
    final enabled = shouldEnableMediaButtons(
      quranPlaying: _quranPlaying,
      quranScreenVisible: _quranScreenVisible,
      appInBackground: _appInBackground,
    );
    try {
      await _routingChannel.invokeMethod(
        'setMediaButtonReceiverEnabled',
        enabled,
      );
    } catch (e) {
      hisnPrint('AppAudioCoordinator: routing update failed: $e');
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _quranPlayingSub?.cancel();
  }
}
