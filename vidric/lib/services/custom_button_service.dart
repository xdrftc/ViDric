import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_button_model.dart';
import '../models/layout_profile.dart';

/// Layanan Kustomisasi Tombol Dinamis (*Custom Button Box Service*).
///
/// Mengelola tombol kustom bebas, pemetaan vJoy Button 1 s/d 32,
/// mode drag-and-drop langsung di kanvas kokpit, dan penyimpanan profil layout JSON.
class CustomButtonService {
  static CustomButtonService? _instance;
  static CustomButtonService get instance => _instance ??= CustomButtonService._();

  @visibleForTesting
  static void resetInstance([CustomButtonService? mockService]) {
    _instance = mockService;
  }

  CustomButtonService._() {
    _activeProfile = ValueNotifier<LayoutProfile>(LayoutProfile.defaultProfile());
    _allProfiles = ValueNotifier<List<LayoutProfile>>([LayoutProfile.defaultProfile()]);
    _isEditMode = ValueNotifier<bool>(false);
    _activeToggleButtons = ValueNotifier<Set<int>>(<int>{});
  }

  static const String _prefKeyProfiles = 'vidric_layout_profiles_json';
  static const String _prefKeyActiveId = 'vidric_active_profile_id';

  late final ValueNotifier<LayoutProfile> _activeProfile;
  late final ValueNotifier<List<LayoutProfile>> _allProfiles;
  late final ValueNotifier<bool> _isEditMode;
  late final ValueNotifier<Set<int>> _activeToggleButtons;

  ValueListenable<LayoutProfile> get activeProfile => _activeProfile;
  ValueListenable<List<LayoutProfile>> get allProfiles => _allProfiles;
  ValueListenable<bool> get isEditMode => _isEditMode;
  ValueListenable<Set<int>> get activeToggleButtons => _activeToggleButtons;

  LayoutProfile get current => _activeProfile.value;
  List<CustomButtonModel> get buttons => _activeProfile.value.buttons;
  bool get editMode => _isEditMode.value;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_prefKeyProfiles);
      final activeId = prefs.getString(_prefKeyActiveId);

      if (profilesJson != null && profilesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(profilesJson) as List<dynamic>;
        final loadedProfiles = decoded
            .map((p) => LayoutProfile.fromJson(p as Map<String, dynamic>))
            .toList();

        if (loadedProfiles.isNotEmpty) {
          _allProfiles.value = loadedProfiles;
          final match = loadedProfiles.firstWhere(
            (p) => p.id == activeId,
            orElse: () => loadedProfiles.first,
          );
          _activeProfile.value = match;
          return;
        }
      }
    } catch (e) {
      debugPrint('CustomButtonService: Gagal memuat profil: $e');
    }

    // Default Fallback
    final def = LayoutProfile.defaultProfile();
    _allProfiles.value = [def];
    _activeProfile.value = def;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_allProfiles.value.map((p) => p.toJson()).toList());
      await prefs.setString(_prefKeyProfiles, encoded);
      await prefs.setString(_prefKeyActiveId, _activeProfile.value.id);
    } catch (e) {
      debugPrint('CustomButtonService: Gagal menyimpan profil: $e');
    }
  }

  void toggleEditMode([bool? force]) {
    _isEditMode.value = force ?? !_isEditMode.value;
  }

  void setSnapToGrid(bool enabled) {
    final updated = current.copyWith(snapToGrid: enabled);
    _updateActiveProfile(updated);
  }

  Future<void> addButton(CustomButtonModel button) async {
    final updatedList = List<CustomButtonModel>.from(current.buttons)..add(button);
    final updatedProfile = current.copyWith(buttons: updatedList);
    _updateActiveProfile(updatedProfile);
    await _persist();
  }

  Future<void> updateButton(CustomButtonModel updated) async {
    final index = current.buttons.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      final updatedList = List<CustomButtonModel>.from(current.buttons);
      updatedList[index] = updated;
      final updatedProfile = current.copyWith(buttons: updatedList);
      _updateActiveProfile(updatedProfile);
      await _persist();
    }
  }

  Future<void> updateButtonPosition(String id, double normalizedX, double normalizedY) async {
    final index = current.buttons.indexWhere((b) => b.id == id);
    if (index != -1) {
      final currentBtn = current.buttons[index];
      final updatedBtn = currentBtn.copyWith(
        normalizedX: normalizedX.clamp(0.0, 1.0),
        normalizedY: normalizedY.clamp(0.0, 1.0),
      );
      final updatedList = List<CustomButtonModel>.from(current.buttons);
      updatedList[index] = updatedBtn;
      final updatedProfile = current.copyWith(buttons: updatedList);
      _updateActiveProfile(updatedProfile);
      await _persist();
    }
  }

  Future<void> deleteButton(String id) async {
    final btn = current.buttons.firstWhere((b) => b.id == id, orElse: () => current.buttons.first);
    _activeToggleButtons.value = Set<int>.from(_activeToggleButtons.value)..remove(btn.vjoyButton);

    final updatedList = current.buttons.where((b) => b.id != id).toList();
    final updatedProfile = current.copyWith(buttons: updatedList);
    _updateActiveProfile(updatedProfile);
    await _persist();
  }

  void toggleButtonState(int vjoyButton) {
    final currentSet = Set<int>.from(_activeToggleButtons.value);
    if (currentSet.contains(vjoyButton)) {
      currentSet.remove(vjoyButton);
    } else {
      currentSet.add(vjoyButton);
    }
    _activeToggleButtons.value = currentSet;
  }

  bool isButtonToggled(int vjoyButton) {
    return _activeToggleButtons.value.contains(vjoyButton);
  }

  void clearToggledButtons() {
    _activeToggleButtons.value = <int>{};
  }

  Future<void> resetToDefaultProfile() async {
    final def = LayoutProfile.defaultProfile();
    _updateActiveProfile(def);
    await _persist();
  }

  Future<void> switchProfile(String profileId) async {
    final match = _allProfiles.value.firstWhere(
      (p) => p.id == profileId,
      orElse: () => _allProfiles.value.first,
    );
    _activeProfile.value = match;
    _activeToggleButtons.value = <int>{};
    await _persist();
  }

  Future<void> createProfile(String name) async {
    final newId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = LayoutProfile(
      id: newId,
      name: name.trim().isEmpty ? 'Profil Kustom' : name.trim(),
      buttons: List<CustomButtonModel>.from(current.buttons),
      snapToGrid: current.snapToGrid,
      gridSize: current.gridSize,
    );

    final updatedProfiles = List<LayoutProfile>.from(_allProfiles.value)..add(newProfile);
    _allProfiles.value = updatedProfiles;
    _activeProfile.value = newProfile;
    await _persist();
  }

  Future<void> deleteProfile(String profileId) async {
    if (profileId == 'default' || _allProfiles.value.length <= 1) {
      return; // Profil default tidak boleh dihapus
    }

    final updatedProfiles = _allProfiles.value.where((p) => p.id != profileId).toList();
    _allProfiles.value = updatedProfiles;
    _activeProfile.value = updatedProfiles.first;
    await _persist();
  }

  void _updateActiveProfile(LayoutProfile updated) {
    _activeProfile.value = updated;
    final index = _allProfiles.value.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      final list = List<LayoutProfile>.from(_allProfiles.value);
      list[index] = updated;
      _allProfiles.value = list;
    }
  }
}
