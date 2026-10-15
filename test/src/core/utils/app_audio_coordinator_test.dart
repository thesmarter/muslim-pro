import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/src/core/utils/app_audio_coordinator.dart';

void main() {
  group('AppAudioCoordinator.shouldEnableMediaButtons', () {
    test('enabled while the Quran screen is open in the foreground', () {
      expect(
        AppAudioCoordinator.shouldEnableMediaButtons(
          quranPlaying: false,
          quranScreenVisible: true,
          appInBackground: false,
        ),
        true,
      );
    });

    test('disabled when idle (no screen, not playing)', () {
      expect(
        AppAudioCoordinator.shouldEnableMediaButtons(
          quranPlaying: false,
          quranScreenVisible: false,
          appInBackground: false,
        ),
        false,
      );
    });

    test('disabled when backgrounded and paused (never wakes recitation)', () {
      expect(
        AppAudioCoordinator.shouldEnableMediaButtons(
          quranPlaying: false,
          quranScreenVisible: true,
          appInBackground: true,
        ),
        false,
      );
    });

    test('enabled when playing in the background (user can pause)', () {
      expect(
        AppAudioCoordinator.shouldEnableMediaButtons(
          quranPlaying: true,
          quranScreenVisible: false,
          appInBackground: true,
        ),
        true,
      );
    });

    test('enabled when playing without the screen', () {
      expect(
        AppAudioCoordinator.shouldEnableMediaButtons(
          quranPlaying: true,
          quranScreenVisible: false,
          appInBackground: false,
        ),
        true,
      );
    });
  });
}
