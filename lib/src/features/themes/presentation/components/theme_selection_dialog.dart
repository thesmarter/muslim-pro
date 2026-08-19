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
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = context.read<ThemeCubit>().state.themePreset;
  }

  void _selectPreset(AppThemePreset preset) {
    if (_selectedPreset?.id == preset.id) return;
    setState(() {
      _selectedPreset = preset;
      _hasChanged = true;
    });
  }

  void _confirmSelection() {
    if (_selectedPreset != null) {
      final cubit = context.read<ThemeCubit>();
      cubit.changePreset(_selectedPreset!);
      cubit.markThemeSelectionShown();
    }
    Navigator.of(context).pop(true);
  }

  void _keepCurrent() {
    context.read<ThemeCubit>().markThemeSelectionShown();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final previewTheme = _selectedPreset?.themeFor(brightness) ?? Theme.of(context);

    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return Dialog(
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
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: AppThemePreset.presets.length,
                      itemBuilder: (context, index) {
                        final preset = AppThemePreset.presets[index];
                        final isSelected = _selectedPreset?.id == preset.id;

                        return _ThemePresetTile(
                          preset: preset,
                          isSelected: isSelected,
                          onTap: () => _selectPreset(preset),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _keepCurrent,
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
                            onPressed: _hasChanged ? _confirmSelection : null,
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
          );
        },
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  final AppThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePresetTile({
    required this.preset,
    required this.isSelected,
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
                      Icons.palette_rounded,
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
                if (isSelected)
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
