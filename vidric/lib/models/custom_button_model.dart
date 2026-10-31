import 'package:flutter/material.dart';

/// Tipe Aksi Tombol Kustom:
/// - toggle: Sakelar terkunci ON/OFF (misal lampu, hazard, diff lock)
/// - momentary: Aktif hanya saat jari menekan layar (misal klakson, engine start, high beam)
enum ButtonTriggerMode {
  toggle,
  momentary,
}

/// Model Tombol Kustom Bebas (*Player-Defined Custom Button Box*).
class CustomButtonModel {
  final String id;
  final String label;
  final int vjoyButton; // 1 s/d 32
  final ButtonTriggerMode triggerMode;
  final String iconKey;
  final double normalizedX; // 0.0 s/d 1.0 (proporsional terhadap lebar layar)
  final double normalizedY; // 0.0 s/d 1.0 (proporsional terhadap tinggi layar)
  final double width;
  final double height;
  final int colorValue;

  const CustomButtonModel({
    required this.id,
    required this.label,
    required this.vjoyButton,
    this.triggerMode = ButtonTriggerMode.toggle,
    this.iconKey = 'lightbulb',
    required this.normalizedX,
    required this.normalizedY,
    this.width = 54.0,
    this.height = 54.0,
    this.colorValue = 0xFF00E5FF,
  });

  bool get isToggle => triggerMode == ButtonTriggerMode.toggle;

  Color get color => Color(colorValue);

  IconData get iconData => getIconData(iconKey);

  static IconData getIconData(String key) {
    switch (key) {
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'arrow_back':
        return Icons.arrow_back_rounded;
      case 'arrow_forward':
        return Icons.arrow_forward_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'power':
        return Icons.power_settings_new_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'flash':
        return Icons.flash_on_rounded;
      case 'volume':
        return Icons.volume_up_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'sports_motorsports':
        return Icons.sports_motorsports_rounded;
      case 'radio':
        return Icons.radio_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  CustomButtonModel copyWith({
    String? id,
    String? label,
    int? vjoyButton,
    ButtonTriggerMode? triggerMode,
    String? iconKey,
    double? normalizedX,
    double? normalizedY,
    double? width,
    double? height,
    int? colorValue,
  }) {
    return CustomButtonModel(
      id: id ?? this.id,
      label: label ?? this.label,
      vjoyButton: vjoyButton ?? this.vjoyButton,
      triggerMode: triggerMode ?? this.triggerMode,
      iconKey: iconKey ?? this.iconKey,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      width: width ?? this.width,
      height: height ?? this.height,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'vjoyButton': vjoyButton,
      'triggerMode': triggerMode.name,
      'iconKey': iconKey,
      'normalizedX': normalizedX,
      'normalizedY': normalizedY,
      'width': width,
      'height': height,
      'colorValue': colorValue,
    };
  }

  factory CustomButtonModel.fromJson(Map<String, dynamic> json) {
    return CustomButtonModel(
      id: json['id'] as String? ?? 'btn_${DateTime.now().millisecondsSinceEpoch}',
      label: json['label'] as String? ?? 'BTN',
      vjoyButton: (json['vjoyButton'] as num?)?.toInt() ?? 1,
      triggerMode: (json['triggerMode'] as String?) == 'momentary'
          ? ButtonTriggerMode.momentary
          : ButtonTriggerMode.toggle,
      iconKey: json['iconKey'] as String? ?? 'lightbulb',
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.5,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.5,
      width: (json['width'] as num?)?.toDouble() ?? 54.0,
      height: (json['height'] as num?)?.toDouble() ?? 54.0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
    );
  }
}
