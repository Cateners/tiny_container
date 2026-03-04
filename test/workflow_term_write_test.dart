import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';

class MockPty implements Pty {
  final List<Uint8List> writtenData = [];

  @override
  void write(Uint8List data) {
    writtenData.add(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTermPty implements TermPty {
  @override
  final Pty pty;

  MockTermPty(this.pty);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Util.termWrite tests', () {
    late MockPty mockPty;
    late MockTermPty mockTermPty;

    setUp(() {
      mockPty = MockPty();
      mockTermPty = MockTermPty(mockPty);

      // Setup global state required for Util.termWrite
      G.currentContainer = 0;
      G.termPtys = {0: mockTermPty};
    });

    test('writes correctly encoded string with appended newline', () {
      const testString = 'echo "Hello World"';

      Util.termWrite(testString);

      expect(mockPty.writtenData.length, 1);
      final writtenBytes = mockPty.writtenData[0];
      final writtenString = const Utf8Decoder().convert(writtenBytes);

      expect(writtenString, '$testString\n');
    });

    test('handles empty string input', () {
      Util.termWrite('');

      expect(mockPty.writtenData.length, 1);
      final writtenBytes = mockPty.writtenData[0];
      final writtenString = const Utf8Decoder().convert(writtenBytes);

      expect(writtenString, '\n');
    });

    test('handles multiple consecutive writes', () {
      Util.termWrite('command1');
      Util.termWrite('command2');

      expect(mockPty.writtenData.length, 2);

      expect(const Utf8Decoder().convert(mockPty.writtenData[0]), 'command1\n');
      expect(const Utf8Decoder().convert(mockPty.writtenData[1]), 'command2\n');
    });

    test('handles special characters and utf8 content', () {
      const testString = 'echo "测试 🌟 😊"';
      Util.termWrite(testString);

      expect(mockPty.writtenData.length, 1);
      final writtenBytes = mockPty.writtenData[0];
      final writtenString = const Utf8Decoder().convert(writtenBytes);

      expect(writtenString, '$testString\n');

      // Verify raw bytes are actually utf8 encoded
      final expectedBytes = const Utf8Encoder().convert('$testString\n');
      expect(writtenBytes, equals(expectedBytes));
    });
  });
}
