import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/services/update_service.dart';

/// The update prompt reappears on every launch until the user updates, so a
/// wrong comparison here nags people who are already current - or stays silent
/// when a real update ships.
void main() {
  group('isNewerVersion', () {
    test('prompts when the hosted version is higher', () {
      expect(UpdateService.isNewerVersion('1.1.5', '1.1.4'), isTrue);
      expect(UpdateService.isNewerVersion('1.2.0', '1.1.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('stays silent once the user has updated', () {
      expect(UpdateService.isNewerVersion('1.1.4', '1.1.4'), isFalse);
      expect(UpdateService.isNewerVersion('1.1.4', '1.1.5'), isFalse);
      expect(UpdateService.isNewerVersion('1.1.4', '2.0.0'), isFalse);
    });

    test('compares numerically, not as text', () {
      // The bug a string comparison would introduce: '1.1.10' < '1.1.9'.
      expect(UpdateService.isNewerVersion('1.1.10', '1.1.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.9', '1.1.10'), isFalse);
      expect(UpdateService.isNewerVersion('1.10.0', '1.9.0'), isTrue);
    });

    test('ignores the build number after +', () {
      expect(UpdateService.isNewerVersion('1.1.5+24', '1.1.4+23'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.4+99', '1.1.4'), isFalse);
    });

    test('treats a shorter version as zero-padded', () {
      expect(UpdateService.isNewerVersion('1.2', '1.1.9'), isTrue);
      expect(UpdateService.isNewerVersion('1.1', '1.1.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.1.0', '1.1'), isFalse);
    });

    test('a malformed hosted version never prompts', () {
      // A typo in the JSON must not nag every user on every launch.
      for (final bad in ['', '   ', 'v1.1.5', '1.1.x', 'latest', '1..5', '-1.0']) {
        expect(UpdateService.isNewerVersion(bad, '1.1.4'), isFalse,
            reason: '"$bad" is not a version number');
      }
    });

    test('tolerates surrounding whitespace', () {
      expect(UpdateService.isNewerVersion(' 1.1.5 ', '1.1.4'), isTrue);
    });
  });
}
