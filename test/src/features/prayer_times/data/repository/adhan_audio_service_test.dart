import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';

void main() {
  late AdhanAudioService adhanService;

  setUp(() {
    adhanService = AdhanAudioService();
    // Since it's a singleton, we might need a way to inject the player for testing
    // or just test the logic that doesn't strictly depend on the internal player instance
    // but for a better test, I'll assume I can access the player if I modify the service slightly
    // or I'll just test the public interface.
  });

  group('AdhanAudioService Tests', () {
    test('muadhins map contains expected keys', () {
      expect(adhanService.muadhins.containsKey('mishary'), true);
      expect(adhanService.muadhins.containsKey('abdulbasit'), true);
      expect(adhanService.muadhins.containsKey('nasser'), true);
    });

    test('muadhins paths are correct', () {
      expect(adhanService.muadhins['mishary'], 'assets/sounds/adhan_mishary.mp3');
    });
    
    // Additional tests would go here, potentially mocking the player internals
    // if the service allowed dependency injection of the player.
  });
}
