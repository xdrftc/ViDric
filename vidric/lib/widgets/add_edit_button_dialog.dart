import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_button_model.dart';

/// Dialog Penambahan & Modifikasi Tombol Kustom Bebas (*Add/Edit Button Dialog*).
class AddEditButtonDialog extends StatefulWidget {
  final CustomButtonModel? initialButton;
  final VoidCallback? onDelete;

  const AddEditButtonDialog({
    super.key,
    this.initialButton,
    this.onDelete,
  });

  @override
  State<AddEditButtonDialog> createState() => _AddEditButtonDialogState();
}

class _AddEditButtonDialogState extends State<AddEditButtonDialog> {
  late TextEditingController _labelController;
  late int _selectedVjoy;
  late ButtonTriggerMode _selectedTriggerMode;
  late String _selectedIconKey;
  late int _selectedColor;

  final List<String> _availableIcons = [
    'lightbulb',
    'warning',
    'water_drop',
    'power',
    'lock',
    'flash',
    'arrow_back',
    'arrow_forward',
    'volume',
    'air',
    'shield',
    'sports_motorsports',
    'radio',
    'star',
  ];

  final List<int> _availableColors = [
    0xFF00E5FF, // Cyan
    0xFF00E676, // Emerald
    0xFFFFB300, // Amber
    0xFFFF1744, // Crimson
    0xFFB388FF, // Purple
    0xFF90A4AE, // Silver
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialButton;
    _labelController = TextEditingController(text: init?.label ?? 'CUSTOM');
    _selectedVjoy = init?.vjoyButton ?? 1;
    _selectedTriggerMode = init?.triggerMode ?? ButtonTriggerMode.toggle;
    _selectedIconKey = init?.iconKey ?? 'lightbulb';
    _selectedColor = init?.colorValue ?? 0xFF00E5FF;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _applyPreset({
    required String label,
    required int vjoy,
    required ButtonTriggerMode mode,
    required String icon,
    required int color,
  }) {
    HapticFeedback.lightImpact();
    setState(() {
      _labelController.text = label;
      _selectedVjoy = vjoy;
      _selectedTriggerMode = mode;
      _selectedIconKey = icon;
      _selectedColor = color;
    });
  }

  void _save() {
    final label = _labelController.text.trim().isEmpty ? 'BTN' : _labelController.text.trim();
    final button = CustomButtonModel(
      id: widget.initialButton?.id ?? 'btn_${DateTime.now().millisecondsSinceEpoch}',
      label: label.toUpperCase(),
      vjoyButton: _selectedVjoy,
      triggerMode: _selectedTriggerMode,
      iconKey: _selectedIconKey,
      normalizedX: widget.initialButton?.normalizedX ?? 0.45,
      normalizedY: widget.initialButton?.normalizedY ?? 0.25,
      width: widget.initialButton?.width ?? 54.0,
      height: widget.initialButton?.height ?? 54.0,
      colorValue: _selectedColor,
    );
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(button);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialButton != null;

    return Dialog(
      backgroundColor: const Color(0xFF131D27),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF26374A), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
                    color: const Color(0xFF00E5FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'EDIT TOMBOL KUSTOM' : 'TAMBAH TOMBOL BARU',
                    style: const TextStyle(
                      color: Color(0xFFE0E6ED),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF7E93A8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E2D3E), height: 16),

              // Form Scrollable
              Expanded(
                child: ListView(
                  children: [
                    // Quick Presets
                    const Text(
                      'PRESET INSTRUMEN KENDARAAN CEPAT:',
                      style: TextStyle(color: Color(0xFF7E93A8), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('💡 Lampu', 'LIGHTS', 1, ButtonTriggerMode.toggle, 'lightbulb', 0xFF00E5FF),
                          const SizedBox(width: 6),
                          _buildPresetChip('⚠️ Hazard', 'HAZARD', 2, ButtonTriggerMode.toggle, 'warning', 0xFFFFB300),
                          const SizedBox(width: 6),
                          _buildPresetChip('🌧️ Wiper', 'WIPER', 5, ButtonTriggerMode.toggle, 'water_drop', 0xFF00E676),
                          const SizedBox(width: 6),
                          _buildPresetChip('⚡ Engine', 'IGNITION', 6, ButtonTriggerMode.momentary, 'power', 0xFFFF1744),
                          const SizedBox(width: 6),
                          _buildPresetChip('🔒 Diff Lock', 'DIFF LOCK', 8, ButtonTriggerMode.toggle, 'lock', 0xFFB388FF),
                          const SizedBox(width: 6),
                          _buildPresetChip('🔦 High Beam', 'HIGH BEAM', 19, ButtonTriggerMode.momentary, 'flash', 0xFF00E5FF),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Label & vJoy Target Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Input
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LABEL TOMBOL:',
                                style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _labelController,
                                maxLength: 10,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'LIGHTS',
                                  hintStyle: const TextStyle(color: Color(0xFF455A64), fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF18232F),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFF283B4E)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFF283B4E)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // vJoy Button Target Dropdown
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TARGET VJOY:',
                                style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18232F),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF283B4E)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedVjoy,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF18232F),
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF), size: 18),
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                    items: List.generate(32, (i) => i + 1).map((btn) {
                                      return DropdownMenuItem<int>(
                                        value: btn,
                                        child: Text('Button $btn'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedVjoy = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Trigger Mode: Toggle vs Momentary
                    const Text(
                      'TIPE AKSI (TRIGGER MODE):',
                      style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTriggerModeTile(
                            mode: ButtonTriggerMode.toggle,
                            title: 'TOGGLE (ON / OFF)',
                            desc: 'Sakelar terkunci (Lampu, Hazard, Diff Lock).',
                            icon: Icons.toggle_on_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTriggerModeTile(
                            mode: ButtonTriggerMode.momentary,
                            title: 'MOMENTARY (PUSH)',
                            desc: 'Aktif hanya saat disentuh (Klakson, Starter).',
                            icon: Icons.touch_app_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Icon Picker
                    const Text(
                      'PILIHAN IKON:',
                      style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((k) {
                        final isSelected = _selectedIconKey == k;
                        return InkWell(
                          onTap: () => setState(() => _selectedIconKey = k),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFF18232F),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF283B4E),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Icon(
                              CustomButtonModel.getIconData(k),
                              size: 18,
                              color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF8FA3B8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Color Picker
                    const Text(
                      'WARNA TEMA:',
                      style: TextStyle(color: Color(0xFFD4E0EC), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _availableColors.map((c) {
                        final isSelected = _selectedColor == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => setState(() => _selectedColor = c),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(c),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(c).withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                children: [
                  if (isEditing && widget.onDelete != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onDelete!();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFFF1744)),
                      label: const Text('HAPUS', style: TextStyle(color: Color(0xFFFF1744), fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5A1A22)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('BATAL', style: TextStyle(color: Color(0xFF7E93A8), fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 14),
                    label: Text(
                      isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAHKAN KE KOKPIT',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0D141C),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    String textVal,
    int vjoy,
    ButtonTriggerMode mode,
    String icon,
    int color,
  ) {
    return InkWell(
      onTap: () => _applyPreset(
        label: textVal,
        vjoy: vjoy,
        mode: mode,
        icon: icon,
        color: color,
      ),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF18232F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF283B4E)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFD4E0EC), fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTriggerModeTile({
    required ButtonTriggerMode mode,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _selectedTriggerMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedTriggerMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFF18232F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF283B4E),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFFE0E6ED),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Color(0xFF7E93A8), fontSize: 8.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
