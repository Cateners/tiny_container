import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';

void main() {
  group('Util.escapeShellArgument', () {
    test('wraps empty string in single quotes', () {
      expect(Util.escapeShellArgument(''), "''");
    });

    test('wraps plain string in single quotes', () {
      expect(Util.escapeShellArgument('hello'), "'hello'");
    });

    test('escapes string with spaces', () {
      expect(Util.escapeShellArgument('hello world'), "'hello world'");
    });

    test('escapes embedded single quotes via end-quote escape start-quote', () {
      expect(Util.escapeShellArgument("hello'world"), "'hello'\\''world'");
    });

    test('escapes shell metacharacters', () {
      expect(
        Util.escapeShellArgument('--opt=val; rm -rf /'),
        "'--opt=val; rm -rf /'",
      );
    });

    test('escapes dollar signs (prevents variable expansion)', () {
      expect(Util.escapeShellArgument(r'$HOME'), r"'$HOME'");
    });

    test('escapes backticks (prevents command substitution)', () {
      expect(Util.escapeShellArgument(r'`id`'), r"'`id`'");
    });
  });
}
