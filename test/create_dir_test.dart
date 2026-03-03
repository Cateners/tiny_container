import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';

void main() {
  group('Util.createDirFromString tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tiny_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates directory recursively', () {
      final testPath = '${tempDir.path}/test_dir/nested_dir';

      // Ensure directory does not exist initially
      expect(Directory(testPath).existsSync(), isFalse);

      // Call the function
      Util.createDirFromString(testPath);

      // Verify directory was created
      expect(Directory(testPath).existsSync(), isTrue);
    });

    test('does not throw when directory already exists', () {
      final testPath = '${tempDir.path}/existing_dir';

      // Create it first
      Directory(testPath).createSync();
      expect(Directory(testPath).existsSync(), isTrue);

      // Call the function again
      Util.createDirFromString(testPath);

      // Still exists, didn't crash
      expect(Directory(testPath).existsSync(), isTrue);
    });

    test('creates directory with special characters', () {
      final testPath = '${tempDir.path}/test dir/nested_dir_with_ñ_ç';

      expect(Directory(testPath).existsSync(), isFalse);

      Util.createDirFromString(testPath);

      expect(Directory(testPath).existsSync(), isTrue);
    });
  });
}
