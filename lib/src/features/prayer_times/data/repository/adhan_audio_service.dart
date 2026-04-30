
import 'package:audio_session/audio_session.dart';
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


  final _player = AudioPlayer();
  String? _currentPlayingMuadhinId;
  String? get currentPlayingMuadhinId => _currentPlayingMuadhinId;

  // Stream for current playing muadhin ID
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
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.alarm, // Use alarm usage to respect alarm volume and potentially bypass silent mode
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ));
    await session.setActive(true);


    // Listen for completion to stop automatically
    _player.processingStateStream.listen((state) {
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
    
    // Set initial volume from settings
    try {
      final settings = sl<PrayerTimesRepo>().getSettings();
      await _player.setVolume(settings.adhanVolume);
      hisnPrint("Initial Adhan volume set to: ${settings.adhanVolume}");
    } catch (e) {
      hisnPrint("Error setting initial volume: $e");
    }
    
    // Initialize stream with null
    _currentMuadhinSubject.add(null);
    
    hisnPrint("Adhan audio player initialized");
  }

  Future<void> playAdhan(String muadhinId) async {
    try {
      hisnPrint("playAdhan requested for: $muadhinId");
      final soundPath = muadhins[muadhinId] ?? muadhins['wadie_alyamani']!;
      hisnPrint("Resolved sound path: $soundPath");
      
      // Stop current if any
      if (_player.playing) {
        hisnPrint("Stopping current playback");
        await _player.stop();
      }

      // Load and play
      _currentPlayingMuadhinId = muadhinId;
      _currentMuadhinSubject.add(muadhinId);
      
      hisnPrint("Setting asset: $soundPath");
      await _player.setAsset(soundPath);
      
      // Ensure volume is set again before playing
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
      // Fallback to default if error
      if (muadhinId != 'wadie_alyamani') {
        hisnPrint("Attempting fallback to default muadhin...");
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
    }
  }

  Future<void> stopAdhan() async {
    try {
      await _player.stop();
      _currentPlayingMuadhinId = null;
      _currentMuadhinSubject.add(null);
      hisnPrint("Adhan stopped");
    } catch (e) {
      hisnPrint("Error stopping adhan: $e");
    }
  }

  Future<void> previewAdhan(String muadhinId) async {
    await stopAdhan();
    await playAdhan(muadhinId);
    // Auto stop preview after 10 seconds
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

        // Show test notification with adhan sound
        await sl<LocalNotificationManager>().showAdhanNotification(
          id: 990 + prayers.indexOf(prayerKey),
          title: "اختبار الأذان: $prayerName",
          body: "اختبار صوت الأذان والإشعار",
          payload: "test_adhan_$muadhinId",
          soundFileName: muadhinId,
          muadhinId: muadhinId,
        );

        // Play each for 5 seconds for testing purposes
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
    _player.dispose();
  }
}
