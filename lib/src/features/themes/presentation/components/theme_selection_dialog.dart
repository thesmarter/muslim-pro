import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/themes/data/models/app_theme_preset.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

class ThemeSelectionDialog extends StatefulWidget {
  const ThemeSelectionDialog({super.key});

  @override
  State<ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<ThemeSelectionDialog> {
  AppThemePreset? _selectedPreset;
  bool _isPreviewing = false;
  int _previewCountdown = 10;
  Timer? _previewTimer;
  AppThemePreset? _originalPreset;

  @override
  void dispose() {
    _previewTimer?.cancel();
    _restoreOriginalTheme();
    super.dispose();
  }

  void _restoreOriginalTheme() {
    if (_isPreviewing && _originalPreset != null && mounted) {
      context.read<ThemeCubit>().changePreset(_originalPreset!);
    }
  }

  void _startPreview(AppThemePreset preset) {
    final themeCubit = context.read<ThemeCubit>();
    _originalPreset = themeCubit.state.themePreset;
    _selectedPreset = preset;
    _isPreviewing = true;
    _previewCountdown = 10;

    themeCubit.changePreset(preset);

    _previewTimer?.cancel();
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _previewCountdown--;
        if (_previewCountdown <= 0) {
          timer.cancel();
          _stopPreview();
        }
      });
    });
    setState(() {});
  }

  void _stopPreview() {
    _previewTimer?.cancel();
    _isPreviewing = false;
    _previewCountdown = 10;

    if (_originalPreset != null && mounted) {
      context.read<ThemeCubit>().changePreset(_originalPreset!);
    }
    _selectedPreset = null;
    if (mounted) setState(() {});
  }

  void _confirmSelection() {
    _previewTimer?.cancel();
    if (_selectedPreset != null) {
      context.read<ThemeCubit>().changePreset(_selectedPreset!);
      context.read<ThemeCubit>().markThemeSelectionShown();
    }
    Navigator.of(context).pop(true);
  }

  void _keepCurrent() {
    _previewTimer?.cancel();
    _restoreOriginalTheme();
    context.read<ThemeCubit>().markThemeSelectionShown();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentPresetId = context.watch<ThemeCubit>().state.themePresetId;

    return PopScope(
      canPop: !_isPreviewing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isPreviewing) {
          _stopPreview();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      color: colorScheme.onPrimary,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.of(context).themeSelectionTitle,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).themeSelectionSubtitle,
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_isPreviewing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: _previewCountdown / 10,
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          S.of(context).themePreviewCountdown(_previewCountdown),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _stopPreview,
                        child: Text(S.of(context).themePreviewCancel),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: AppThemePreset.presets.length,
                  itemBuilder: (context, index) {
                    final preset = AppThemePreset.presets[index];
                    final isSelected = _selectedPreset?.id == preset.id ||
                        (!_isPreviewing && currentPresetId == preset.id);

                    return _ThemePresetTile(
                      preset: preset,
                      isSelected: isSelected,
                      isPreviewing: _isPreviewing && _selectedPreset?.id == preset.id,
                      onTap: () {
                        if (_isPreviewing) return;
                        _startPreview(preset);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isPreviewing ? null : _keepCurrent,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(S.of(context).themeMigrationKeep),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isPreviewing ? _confirmSelection : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(S.of(context).themeSelectionConfirm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  final AppThemePreset preset;
  final bool isSelected;
  final bool isPreviewing;
  final VoidCallback onTap;

  const _ThemePresetTile({
    required this.preset,
    required this.isSelected,
    required this.isPreviewing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        preset.previewPrimary,
                        preset.previewSecondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: preset.previewPrimary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isPreviewing
                          ? Icons.play_circle_fill
                          : Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.of(context).themeSelectionTapToPreview,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPreviewing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      S.of(context).themePreviewActive,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
