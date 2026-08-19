import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class MuslimBottomNavBar extends StatelessWidget {
  const MuslimBottomNavBar({
    required this.navBarConfig,
    this.navBarDecoration = const NavBarDecoration(),
    this.itemAnimationProperties = const ItemAnimation(),
    this.height = 72,
    super.key,
  });

  final NavBarConfig navBarConfig;
  final NavBarDecoration navBarDecoration;
  final ItemAnimation itemAnimationProperties;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    final surfaceAlpha = brightness == Brightness.dark ? 0.85 : 0.92;

    return DecoratedNavBar(
      decoration: NavBarDecoration(
        color: colorScheme.surface.withValues(alpha: surfaceAlpha),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.dark ? 0.25 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      ),
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navBarConfig.items.length, (index) {
            final isSelected = navBarConfig.selectedIndex == index;
            return _NavBarItem(
              item: navBarConfig.items[index],
              isSelected: isSelected,
              colorScheme: colorScheme,
              animationProperties: itemAnimationProperties,
              onTap: () => navBarConfig.onItemSelected(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.colorScheme,
    required this.animationProperties,
    required this.onTap,
  });

  final ItemConfig item;
  final bool isSelected;
  final ColorScheme colorScheme;
  final ItemAnimation animationProperties;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: animationProperties.duration,
        curve: animationProperties.curve,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IconTheme(
                key: ValueKey<bool>(isSelected),
                data: IconThemeData(
                  size: isSelected ? 26 : 24,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                child: isSelected ? item.icon : item.inactiveIcon,
              ),
            ),
            if (isSelected && item.title != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.title!,
                  style: item.textStyle.apply(
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
