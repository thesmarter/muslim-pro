import 'package:flutter/material.dart';

class QuranAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAudioTap;
  final VoidCallback? onSettingsTap;

  const QuranAppBar({
    super.key,
    required this.title,
    this.onSearchTap,
    this.onAudioTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative pattern
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (onSearchTap != null)
          IconButton(
            onPressed: onSearchTap,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        if (onAudioTap != null)
          IconButton(
            onPressed: onAudioTap,
            icon: const Icon(Icons.headphones),
            tooltip: 'Audio Player',
          ),
        if (onSettingsTap != null)
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
