import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onFilterTap;
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.onFilterTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: context.colorInputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: context.colorTextHint, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: context.colorTextSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: AppDimensions.spacingMD),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: context.colorInputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.tune, color: context.colorTextPrimary),
              onPressed: onFilterTap,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(width: AppDimensions.spacingMD),
          trailing!,
        ],
      ],
    );
  }
}