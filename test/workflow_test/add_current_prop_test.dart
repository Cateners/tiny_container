import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:da_ripped_tiny_computer/workflow.dart';
import 'package:da_ripped_tiny_computer/settings.dart';
import 'package:da_ripped_tiny_computer/models.dart';

void main() {
  group('Util.addCurrentProp tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Setup mock initial values for SharedPreferences
      final container1 = ContainerInfo(
        name: 'Container 1',
        boot: 'boot_cmd_1',
        vnc: 'vnc_cmd_1',
        vncPassword: 'password1',
        vncUrl: 'url1',
        vncUri: 'uri1',
        commands: [],
      );

      final container2 = ContainerInfo(
        name: 'Container 2',
        boot: 'boot_cmd_2',
        vnc: 'vnc_cmd_2',
        vncPassword: 'password_2',
        vncUrl: 'url2',
        vncUri: 'uri2',
        commands: [],
        additionalProps: {'existing_custom_prop': 'custom_value'},
      );

      final initialData = <String, Object>{
        'containersInfo': [
          jsonEncode(container1.toJson()),
          jsonEncode(container2.toJson()),
        ],
      };

      SharedPreferences.setMockInitialValues(initialData);
      prefs = await SharedPreferences.getInstance();

      // Initialize globals
      G.prefs = prefs;
      G.settings = GlobalSettings();
      await G.settings.init(prefs);

      // Default container index
      G.currentContainer = 0;
    });

    test('updates an existing known property (e.g. name) successfully',
        () async {
      G.currentContainer = 0; // Targeting Container 1
      await Util.addCurrentProp('name', 'Updated Container 1');

      final updatedContainersList = prefs.getStringList('containersInfo')!;
      final updatedContainer1Json = jsonDecode(updatedContainersList[0]);

      expect(updatedContainer1Json['name'], 'Updated Container 1');
      // Ensure other properties remain unchanged
      expect(updatedContainer1Json['vncPassword'], 'password1');
    });

    test('adds a new/unknown property successfully into additionalProps',
        () async {
      G.currentContainer = 0;
      await Util.addCurrentProp('new_custom_theme', 'dark_mode');

      final updatedContainersList = prefs.getStringList('containersInfo')!;
      final updatedContainer1Json = jsonDecode(updatedContainersList[0]);

      expect(updatedContainer1Json['new_custom_theme'], 'dark_mode');
    });

    test('updates property for the correct container without affecting others',
        () async {
      G.currentContainer = 1; // Targeting Container 2
      await Util.addCurrentProp('vncPassword', 'new_secure_password_2');

      final updatedContainersList = prefs.getStringList('containersInfo')!;

      // Container 1 should remain unaffected
      final container1Json = jsonDecode(updatedContainersList[0]);
      expect(container1Json['vncPassword'], 'password1');

      // Container 2 should be updated
      final container2Json = jsonDecode(updatedContainersList[1]);
      expect(container2Json['vncPassword'], 'new_secure_password_2');
      // Container 2's existing additional props should also remain unaffected
      expect(container2Json['existing_custom_prop'], 'custom_value');
    });

    test('handles null value properly', () async {
      G.currentContainer = 0;
      await Util.addCurrentProp('nullable_prop', null);

      final updatedContainersList = prefs.getStringList('containersInfo')!;
      final containerJson = jsonDecode(updatedContainersList[0]);

      expect(containerJson.containsKey('nullable_prop'), isTrue);
      expect(containerJson['nullable_prop'], isNull);
    });

    test('throws RangeError when currentContainer is out of bounds', () async {
      G.currentContainer = 99; // Invalid index

      expect(
        () async => await Util.addCurrentProp('key', 'value'),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
