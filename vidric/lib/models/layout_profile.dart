import 'custom_button_model.dart';

/// Profil Konfigurasi Tata Letak Kokpit (*Layout Profile*).
class LayoutProfile {
  final String id;
  final String name;
  final List<CustomButtonModel> buttons;
  final bool snapToGrid;
  final double gridSize;

  const LayoutProfile({
    required this.id,
    required this.name,
    required this.buttons,
    this.snapToGrid = true,
    this.gridSize = 16.0,
  });

  /// Profil standar bawaan pabrik dengan preset tombol instrumen kendaraan populer.
  factory LayoutProfile.defaultProfile() {
    return const LayoutProfile(
      id: 'default',
      name: 'Default Cockpit',
      snapToGrid: true,
      gridSize: 16.0,
      buttons: [
        CustomButtonModel(
          id: 'btn_light',
          label: 'LIGHTS',
          vjoyButton: 1,
          triggerMode: ButtonTriggerMode.toggle,
          iconKey: 'lightbulb',
          normalizedX: 0.14,
          normalizedY: 0.22,
          colorValue: 0xFF00E5FF,
        ),
        CustomButtonModel(
          id: 'btn_hazard',
          label: 'HAZARD',
          vjoyButton: 2,
          triggerMode: ButtonTriggerMode.toggle,
          iconKey: 'warning',
          normalizedX: 0.22,
          normalizedY: 0.22,
          colorValue: 0xFFFFB300,
        ),
        CustomButtonModel(
          id: 'btn_wiper',
          label: 'WIPER',
          vjoyButton: 5,
          triggerMode: ButtonTriggerMode.toggle,
          iconKey: 'water_drop',
          normalizedX: 0.30,
          normalizedY: 0.22,
          colorValue: 0xFF00E676,
        ),
      ],
    );
  }

  LayoutProfile copyWith({
    String? id,
    String? name,
    List<CustomButtonModel>? buttons,
    bool? snapToGrid,
    double? gridSize,
  }) {
    return LayoutProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      buttons: buttons ?? this.buttons,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'snapToGrid': snapToGrid,
      'gridSize': gridSize,
      'buttons': buttons.map((b) => b.toJson()).toList(),
    };
  }

  factory LayoutProfile.fromJson(Map<String, dynamic> json) {
    final list = json['buttons'] as List<dynamic>? ?? [];
    return LayoutProfile(
      id: json['id'] as String? ?? 'default',
      name: json['name'] as String? ?? 'Custom Profile',
      snapToGrid: json['snapToGrid'] as bool? ?? true,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 16.0,
      buttons: list
          .map((b) => CustomButtonModel.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

