import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';

void main() {
  group('Util.isXServerReady', () {
    test('returns true when connection succeeds', () async {
      // Start a local server socket to simulate a ready X server
      final serverSocket = await ServerSocket.bind('127.0.0.1', 0);
      final port = serverSocket.port;

      final isReady = await Util.isXServerReady('127.0.0.1', port);

      expect(isReady, isTrue);

      await serverSocket.close();
    });

    test('returns false when connection fails (connection refused)', () async {
      final isReady = await Util.isXServerReady(
        '127.0.0.1',
        59999,
        timeoutSeconds: 1,
        connectSocket: (host, port, {timeout}) async =>
            throw const SocketException('Connection refused'),
      );

      expect(isReady, isFalse);
    });

    test('returns false when connection times out', () async {
      final isReady = await Util.isXServerReady(
        '10.255.255.255',
        80,
        timeoutSeconds: 1,
        connectSocket: (host, port, {timeout}) async =>
            throw TimeoutException('Connection timed out'),
      );

      expect(isReady, isFalse);
    });
  });
}
