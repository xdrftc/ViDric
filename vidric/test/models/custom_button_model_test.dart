import 'package:flutter_test/flutter_test.dart';
import 'package:vidric/models/custom_button_model.dart';
import 'package:vidric/models/layout_profile.dart';

void main() {
  group('CustomButtonModel Unit Tests', () {
    test('serializes and deserializes CustomButtonModel correctly', () {
      const button = CustomButtonModel(
        id: 'btn_test_1',
        label: 'HEADLIGHTS',
        vjoyButton: 3,
        triggerMode: ButtonTriggerMode.toggle,
        iconKey: 'lightbulb',
        normalizedX: 0.25,
        normalizedY: 0.40,
        width: 60.0,
        height: 60.0,
        colorValue: 0xFF00E5FF,
      );

      final json = button.toJson();
      expect(json['id'], 'btn_test_1');
      expect(json['label'], 'HEADLIGHTS');
      expect(json['vjoyButton'], 3);
      expect(json['triggerMode'], 'toggle');
      expect(json['iconKey'], 'lightbulb');
      expect(json['normalizedX'], 0.25);
      expect(json['normalizedY'], 0.40);

      final restored = CustomButtonModel.fromJson(json);
      expect(restored.id, button.id);
      expect(restored.label, button.label);
      expect(restored.vjoyButton, button.vjoyButton);
      expect(restored.triggerMode, ButtonTriggerMode.toggle);
      expect(restored.isToggle, true);
    });

    test('copyWith updates specified properties while preserving others', () {
      const button = CustomButtonModel(
        id: 'btn_orig',
        label: 'HORN',
        vjoyButton: 7,
        triggerMode: ButtonTriggerMode.momentary,
        normalizedX: 0.1,
        normalizedY: 0.1,
      );

      final updated = button.copyWith(
        label: 'SIREN',
        vjoyButton: 8,
        normalizedX: 0.85,
      );

      expect(updated.id, 'btn_orig');
      expect(updated.label, 'SIREN');
      expect(updated.vjoyButton, 8);
      expect(updated.normalizedX, 0.85);
      expect(updated.normalizedY, 0.1);
      expect(updated.isToggle, false);
    });
  });

  group('LayoutProfile Unit Tests', () {
    test('defaultProfile provides pre-configured automotive buttons', () {
      final profile = LayoutProfile.defaultProfile();
      expect(profile.id, 'default');
      expect(profile.name, 'Default Cockpit');
      expect(profile.snapToGrid, true);
      expect(profile.buttons.length, greaterThanOrEqualTo(3));

      final vjoyButtons = profile.buttons.map((b) => b.vjoyButton).toList();
      expect(vjoyButtons, contains(1)); // LIGHTS
      expect(vjoyButtons, contains(2)); // HAZARD
    });

    test('serializes and deserializes LayoutProfile JSON', () {
      final profile = LayoutProfile.defaultProfile();
      final json = profile.toJson();

      expect(json['id'], 'default');
      expect(json['snapToGrid'], true);
      expect(json['buttons'] is List, true);

      final restored = LayoutProfile.fromJson(json);
      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.buttons.length, profile.buttons.length);
    });
  });
}

