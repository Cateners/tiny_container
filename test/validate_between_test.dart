
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';
import 'package:da_ripped_tiny_computer/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('Util.validateBetween edge cases', (WidgetTester tester) async {
    String? lastError;
    bool oprCalled = false;
    void opr() {
      oprCalled = true;
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            G.homePageStateContext = context;
            return const Scaffold(body: Placeholder());
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Test Case: Null value
    oprCalled = false;
    lastError = Util.validateBetween(null, 1, 10, opr);
    expect(lastError, isNotNull);
    expect(lastError, AppLocalizations.of(G.homePageStateContext)!.enterNumber);
    expect(oprCalled, isFalse);

    // Test Case: Empty value
    oprCalled = false;
    lastError = Util.validateBetween('', 1, 10, opr);
    expect(lastError, isNotNull);
    expect(lastError, AppLocalizations.of(G.homePageStateContext)!.enterNumber);
    expect(oprCalled, isFalse);

    // Test Case: Non-numeric value
    oprCalled = false;
    lastError = Util.validateBetween('abc', 1, 10, opr);
    expect(lastError, isNotNull);
    expect(lastError, AppLocalizations.of(G.homePageStateContext)!.enterValidNumber);
    expect(oprCalled, isFalse);

    // Test Case: Value less than min
    oprCalled = false;
    lastError = Util.validateBetween('0', 1, 10, opr);
    expect(lastError, isNotNull);
    expect(lastError, AppLocalizations.of(G.homePageStateContext)!.enterNumberBetween(1, 10));
    expect(oprCalled, isFalse);

    // Test Case: Value greater than max
    oprCalled = false;
    lastError = Util.validateBetween('11', 1, 10, opr);
    expect(lastError, isNotNull);
    expect(lastError, AppLocalizations.of(G.homePageStateContext)!.enterNumberBetween(1, 10));
    expect(oprCalled, isFalse);

    // Test Case: Exactly min
    oprCalled = false;
    lastError = Util.validateBetween('1', 1, 10, opr);
    expect(lastError, isNull);
    expect(oprCalled, isTrue);

    // Test Case: Exactly max
    oprCalled = false;
    lastError = Util.validateBetween('10', 1, 10, opr);
    expect(lastError, isNull);
    expect(oprCalled, isTrue);

    // Test Case: Within range
    oprCalled = false;
    lastError = Util.validateBetween('5', 1, 10, opr);
    expect(lastError, isNull);
    expect(oprCalled, isTrue);
  });
}
