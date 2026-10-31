import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_button_model.dart';
import '../models/layout_profile.dart';
import '../services/custom_button_service.dart';
import 'add_edit_button_dialog.dart';

/// Lapisan Tombol Kustom Dinamis (*Dynamic Custom Button Box Layer*).
///
/// Menyediakan kanvas bebas di atas layar kokpit dengan dua mode operasional:
/// 1. Play Mode: Tombol dapat ditekan (Toggle ON/OFF atau Momentary Push) untuk memicu vJoy Button 1-32.
/// 2. Edit Mode: Pengguna dapat menggeser (Drag & Drop) posisi tombol, menambah (+), mengedit, dan menghapus dengan Snap to Grid.
class DynamicButtonLayer extends StatelessWidget {
  final double opacity;
  final double scale;
  final void Function(int vjoyButton, bool isPressed) onButtonStateChanged;

  const DynamicButtonLayer({
    super.key,
    this.opacity = 1.0,
    this.scale = 1.0,
    required this.onButtonStateChanged,
  });

  CustomButtonService get _service => CustomButtonService.instance;

  Future<void> _openAddDialog(BuildContext context) async {
    final newButton = await showDialog<CustomButtonModel>(
      context: context,
      builder: (context) => const AddEditButtonDialog(),
    );
    if (newButton != null) {
      await _service.addButton(newButton);
    }
  }

  Future<void> _openEditDialog(BuildContext context, CustomButtonModel button) async {
    final updated = await showDialog<CustomButtonModel>(
      context: context,
      builder: (context) => AddEditButtonDialog(
        initialButton: button,
        onDelete: () => _service.deleteButton(button.id),
      ),
    );
    if (updated != null) {
      await _service.updateButton(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isEditMode,
      builder: (context, isEditing, _) {
        return ValueListenableBuilder<LayoutProfile>(
          valueListenable: _service.activeProfile,
          builder: (context, profile, _) {
            return ValueListenableBuilder<Set<int>>(
              valueListenable: _service.activeToggleButtons,
              builder: (context, activeToggles, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = constraints.maxWidth;
                    final canvasHeight = constraints.maxHeight;

                    return Stack(
                      children: [
                        // 1. Grid Visualizer saat Edit Mode
                        if (isEditing && profile.snapToGrid)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(gridSize: profile.gridSize),
                            ),
                          ),

                        // 2. Toolbar Kontrol Atas saat Edit Mode
                        if (isEditing)
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131D27).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF00E5FF)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'EDIT MODE: DRAG & DROP',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Tombol Tambah
                                  InkWell(
                                    onTap: () => _openAddDialog(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2D3D),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF2E4357)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add, size: 12, color: Color(0xFF00E676)),
                                          SizedBox(width: 4),
                                          Text(
                                            'TAMBAH (+)',
                                            style: TextStyle(
                                              color: Color(0xFF00E676),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Toggle Snap to Grid
                                  InkWell(
                                    onTap: () => _service.setSnapToGrid(!profile.snapToGrid),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: profile.snapToGrid ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFF1E2D3D),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: profile.snapToGrid ? const Color(0xFF00E5FF) : const Color(0xFF2E4357),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.grid_4x4_rounded,
                                            size: 12,
                                            color: profile.snapToGrid ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            profile.snapToGrid ? 'GRID: ON' : 'GRID: OFF',
                                            style: TextStyle(
                                              color: profile.snapToGrid ? const Color(0xFF00E5FF) : const Color(0xFF7E93A8),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tombol Selesai
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      _service.toggleEditMode(false);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, size: 12, color: Color(0xFF0D141C)),
                                          SizedBox(width: 4),
                                          Text(
                                            'SELESAI',
                                            style: TextStyle(
                                              color: Color(0xFF0D141C),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 3. Tombol-Tombol Kustom
                        ...profile.buttons.map((btn) {
                          final double btnWidth = btn.width * scale;
                          final double btnHeight = btn.height * scale;

                          // Hitung koordinat absolut pixel
                          double pixelX = (btn.normalizedX * canvasWidth) - (btnWidth / 2);
                          double pixelY = (btn.normalizedY * canvasHeight) - (btnHeight / 2);

                          // Pastikan berada di dalam batas kanvas
                          pixelX = pixelX.clamp(0.0, (canvasWidth - btnWidth).clamp(0.0, double.infinity));
                          pixelY = pixelY.clamp(0.0, (canvasHeight - btnHeight).clamp(0.0, double.infinity));

                          final bool isToggledOn = activeToggles.contains(btn.vjoyButton);

                          return Positioned(
                            left: pixelX,
                            top: pixelY,
                            child: _buildDraggableButton(
                              context: context,
                              button: btn,
                              isEditing: isEditing,
                              isToggledOn: isToggledOn,
                              btnWidth: btnWidth,
                              btnHeight: btnHeight,
                              canvasWidth: canvasWidth,
                              canvasHeight: canvasHeight,
                              snapToGrid: profile.snapToGrid,
                              gridSize: profile.gridSize,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableButton({
    required BuildContext context,
    required CustomButtonModel button,
    required bool isEditing,
    required bool isToggledOn,
    required double btnWidth,
    required double btnHeight,
    required double canvasWidth,
    required double canvasHeight,
    required bool snapToGrid,
    required double gridSize,
  }) {
    final color = button.color;

    Widget buttonContent = Opacity(
      opacity: opacity.clamp(0.2, 1.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: btnWidth,
        height: btnHeight,
        decoration: BoxDecoration(
          color: isToggledOn
              ? color.withValues(alpha: 0.35)
              : (isEditing ? const Color(0xFF1B2836) : const Color(0xFF18222D)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEditing
                ? const Color(0xFF00E5FF)
                : (isToggledOn ? color : const Color(0xFF2E4052)),
            width: isEditing || isToggledOn ? 1.8 : 1.0,
          ),
          boxShadow: isToggledOn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : (isEditing
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ]
                  : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              button.iconData,
              size: btnWidth * 0.38,
              color: isToggledOn ? color : (isEditing ? const Color(0xFF00E5FF) : const Color(0xFF8FA3B8)),
            ),
            const SizedBox(height: 2),
            Text(
              button.label,
              style: TextStyle(
                color: isToggledOn ? Colors.white : const Color(0xFFBAC7D5),
                fontSize: (btnWidth * 0.16).clamp(8.0, 11.0),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isEditing)
              Text(
                'vJ:${button.vjoyButton}',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 7.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );

    if (isEditing) {
      // Gesture Drag & Drop saat Edit Mode
      return GestureDetector(
        onTap: () => _openEditDialog(context, button),
        onPanUpdate: (details) {
          double newPixelX = (button.normalizedX * canvasWidth) + details.delta.dx;
          double newPixelY = (button.normalizedY * canvasHeight) + details.delta.dy;

          if (snapToGrid && gridSize > 0) {
            newPixelX = (newPixelX / gridSize).round() * gridSize;
            newPixelY = (newPixelY / gridSize).round() * gridSize;
          }

          final double normX = (newPixelX / canvasWidth).clamp(0.05, 0.95);
          final double normY = (newPixelY / canvasHeight).clamp(0.08, 0.92);

          _service.updateButtonPosition(button.id, normX, normY);
        },
        child: buttonContent,
      );
    }

    // Interaksi Tekan saat Play Mode
    if (button.isToggle) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _service.toggleButtonState(button.vjoyButton);
          final newState = _service.isButtonToggled(button.vjoyButton);
          onButtonStateChanged(button.vjoyButton, newState);
        },
        child: buttonContent,
      );
    } else {
      // Mode Momentary (Aktif saat ditekan, lepas saat diangkat)
      return GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _service.toggleButtonState(button.vjoyButton);
          onButtonStateChanged(button.vjoyButton, true);
        },
        onTapUp: (_) {
          _service.toggleButtonState(button.vjoyButton);
          onButtonStateChanged(button.vjoyButton, false);
        },
        onTapCancel: () {
          _service.toggleButtonState(button.vjoyButton);
          onButtonStateChanged(button.vjoyButton, false);
        },
        child: buttonContent,
      );
    }
  }
}

/// Painter untuk render titik-titik kisi Snap to Grid
class _GridPainter extends CustomPainter {
  final double gridSize;

  const _GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.gridSize != gridSize;
}

