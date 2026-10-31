import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidric/models/custom_button_model.dart';
import 'package:vidric/services/custom_button_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CustomButtonService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CustomButtonService.resetInstance();
    service = CustomButtonService.instance;
    await service.init();
  });

  group('CustomButtonService Unit Tests', () {
    test('initializes with default profile and preset buttons', () {
      expect(service.current.id, 'default');
      expect(service.buttons.isNotEmpty, true);
      expect(service.editMode, false);
      expect(service.activeToggleButtons.value, isEmpty);
    });

    test('adds, updates and deletes a custom button', () async {
      const newBtn = CustomButtonModel(
        id: 'btn_nitrous',
        label: 'NITRO',
        vjoyButton: 24,
        triggerMode: ButtonTriggerMode.momentary,
        iconKey: 'flash',
        normalizedX: 0.5,
        normalizedY: 0.5,
      );

      await service.addButton(newBtn);
      expect(service.buttons.any((b) => b.id == 'btn_nitrous'), true);

      // Update position
      await service.updateButtonPosition('btn_nitrous', 0.8, 0.7);
      final updated = service.buttons.firstWhere((b) => b.id == 'btn_nitrous');
      expect(updated.normalizedX, 0.8);
      expect(updated.normalizedY, 0.7);

      // Delete button
      await service.deleteButton('btn_nitrous');
      expect(service.buttons.any((b) => b.id == 'btn_nitrous'), false);
    });

    test('toggles toggle button state and manages active set', () {
      expect(service.isButtonToggled(1), false);

      service.toggleButtonState(1);
      expect(service.isButtonToggled(1), true);
      expect(service.activeToggleButtons.value, contains(1));

      service.toggleButtonState(1);
      expect(service.isButtonToggled(1), false);
      expect(service.activeToggleButtons.value, isNot(contains(1)));
    });

    test('creates new profile and switches between profiles', () async {
      await service.createProfile('ETS2 Heavy Cargo');
      expect(service.current.name, 'ETS2 Heavy Cargo');
      expect(service.allProfiles.value.length, 2);

      // Switch back to default
      await service.switchProfile('default');
      expect(service.current.name, 'Default Cockpit');
    });

    test('toggles edit mode on and off', () {
      expect(service.editMode, false);

      service.toggleEditMode(true);
      expect(service.editMode, true);

      service.toggleEditMode();
      expect(service.editMode, false);
    });
  });
}

