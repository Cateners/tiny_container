import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';
import 'dart:io';

void main() {
  setUp(() {
    // Reset ProcessRunner before each test
    ShizukuHelper.processRunner = Process.run;
  });

  test('ShizukuHelper.init sets isAvailable to true when rish is available', () async {
    ShizukuHelper.processRunner = (executable, arguments, {
      workingDirectory, environment, includeParentEnvironment = true, runInShell = false, stdoutEncoding, stderrEncoding
    }) async {
      if (executable == 'sh' && arguments.contains('command -v rish')) {
        return ProcessResult(0, 0, '/system/bin/rish', '');
      }
      return ProcessResult(0, 127, '', 'not found');
    };

    await ShizukuHelper.init();
    expect(ShizukuHelper.isAvailable, true);
  });

  test('ShizukuHelper.init sets isAvailable to false when rish is not available', () async {
    ShizukuHelper.processRunner = (executable, arguments, {
      workingDirectory, environment, includeParentEnvironment = true, runInShell = false, stdoutEncoding, stderrEncoding
    }) async {
      return ProcessResult(0, 127, '', 'not found');
    };

    await ShizukuHelper.init();
    expect(ShizukuHelper.isAvailable, false);
  });

  test('ShizukuHelper.init sets isAvailable to false when process runner throws', () async {
    ShizukuHelper.processRunner = (executable, arguments, {
      workingDirectory, environment, includeParentEnvironment = true, runInShell = false, stdoutEncoding, stderrEncoding
    }) async {
      throw const ProcessException('sh', ['-c', 'command -v rish']);
    };

    await ShizukuHelper.init();
    expect(ShizukuHelper.isAvailable, false);
  });

  test('ShizukuHelper.run uses rish when available', () async {
    List<String> lastExec = [];
    ShizukuHelper.processRunner = (executable, arguments, {
      workingDirectory, environment, includeParentEnvironment = true, runInShell = false, stdoutEncoding, stderrEncoding
    }) async {
      lastExec = [executable, ...arguments];
      if (executable == 'sh' && arguments.contains('command -v rish')) {
        return ProcessResult(0, 0, '/system/bin/rish', '');
      }
      return ProcessResult(0, 0, 'success', '');
    };

    await ShizukuHelper.init(); // Sets _available to true
    expect(ShizukuHelper.isAvailable, true);

    await ShizukuHelper.run('ls -l');
    expect(lastExec[0], 'rish');
    expect(lastExec[1], '-c');
    expect(lastExec[2], 'ls -l');
  });

  test('ShizukuHelper.run uses sh when not available', () async {
    List<String> lastExec = [];
    ShizukuHelper.processRunner = (executable, arguments, {
      workingDirectory, environment, includeParentEnvironment = true, runInShell = false, stdoutEncoding, stderrEncoding
    }) async {
      lastExec = [executable, ...arguments];
      return ProcessResult(0, 127, '', 'not found');
    };

    await ShizukuHelper.init(); // Sets _available to false
    expect(ShizukuHelper.isAvailable, false);

    await ShizukuHelper.run('ls -l');
    expect(lastExec[0], 'sh');
    expect(lastExec[1], '-c');
    expect(lastExec[2], 'ls -l');
  });
}
