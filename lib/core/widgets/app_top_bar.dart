import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerToggle;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.showDrawerToggle = true,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            )
          : showDrawerToggle
              ? IconButton(
                  icon: const Icon(Icons.menu, size: 26),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }
}
