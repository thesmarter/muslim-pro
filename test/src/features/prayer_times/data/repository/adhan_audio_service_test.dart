import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';

void main() {
  // just_audio / audio_session create a MethodChannel handler in their
  // constructors, which requires a binding. Without this the service
  // singleton throws "Cannot set the method call handler before the binary
  // messenger has been initialized".
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Headless note: there is no native audio implementation in `flutter test`.
    // AudioSession.instance catches MissingPluginException internally, but we
    // still install no-op handlers so constructing AdhanAudioService (which
    // creates an AudioPlayer) never surfaces unhandled channel errors.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('adhan_scheduler'),
      (MethodCall call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (MethodCall call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (MethodCall call) async => <String, dynamic>{},
    );
  });

  late AdhanAudioService adhanService;

  setUp(() {
    adhanService = AdhanAudioService();
  });

  group('AdhanAudioService Tests', () {
    test('muadhins map contains expected keys', () {
      for (final id in <String>[
        'siddiq_hamdoun',
        'abdul_basit',
        'farooq_hadrawi',
        'noreen_mohammed',
        'wadie_alyamani',
        'yasser_alhouri',
      ]) {
        expect(adhanService.muadhins.containsKey(id), true, reason: 'missing $id');
      }
      expect(adhanService.muadhins.length, 6);
    });

    test('muadhins paths are correct', () {
      expect(adhanService.muadhins['wadie_alyamani'],
          'assets/sounds/azhan/wadie_alyamani.mp3');
      expect(adhanService.muadhins['abdul_basit'],
          'assets/sounds/azhan/abdul_basit.mp3');
      // Every entry follows assets/sounds/azhan/<id>.mp3.
      for (final entry in adhanService.muadhins.entries) {
        expect(entry.value, 'assets/sounds/azhan/${entry.key}.mp3');
      }
    });
  });
}
