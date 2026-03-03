import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';

void main() {
  group('Util.waitForXServer', () {
    test('resolves immediately if X server is ready', () async {
      int checkCount = 0;
      Future<bool> mockIsReadyCheck(String host, int port) async {
        checkCount++;
        return true;
      }

      final stopwatch = Stopwatch()..start();
      await Util.waitForXServer(timeoutSeconds: 5, isReadyCheck: mockIsReadyCheck);
      stopwatch.stop();

      expect(checkCount, 1);
      // It should complete well under 1 second since it doesn't need to delay
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('resolves after a delay when X server becomes ready later', () async {
      int checkCount = 0;
      Future<bool> mockIsReadyCheck(String host, int port) async {
        checkCount++;
        if (checkCount < 3) {
          return false;
        }
        return true;
      }

      final stopwatch = Stopwatch()..start();
      await Util.waitForXServer(timeoutSeconds: 5, isReadyCheck: mockIsReadyCheck);
      stopwatch.stop();

      expect(checkCount, 3);
      // It should have waited twice, so ~2 seconds elapsed.
      // We check that it took at least 1.5s, but less than 3s.
      expect(stopwatch.elapsedMilliseconds, greaterThan(1500));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('throws TimeoutException if X server is never ready within timeout', () async {
      int checkCount = 0;
      Future<bool> mockIsReadyCheck(String host, int port) async {
        checkCount++;
        return false;
      }

      final stopwatch = Stopwatch()..start();

      try {
        await Util.waitForXServer(timeoutSeconds: 2, isReadyCheck: mockIsReadyCheck);
        fail('Should have thrown TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
        expect((e as TimeoutException).message, contains('X server did not start within 2 seconds'));
      }
      stopwatch.stop();

      // Since timeout is 2 seconds, and each iteration adds 1 sec delay,
      // the loop will break after ~2 seconds.
      expect(checkCount, greaterThanOrEqualTo(2));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(1500));
    });
  });
}
