import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isFullWidth;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  // Legacy compatibility constructor
  const AppButton.legacy({
    super.key,
    required this.label,
    this.onPressed,
    bool isPrimary = true,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  }) : variant = isPrimary ? AppButtonVariant.primary : AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors based on variant
    Color? backgroundColor;
    Color? foregroundColor;
    BorderSide? side;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.onSurface;
        side = BorderSide(color: theme.dividerColor);
        break;
      case AppButtonVariant.danger:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = theme.colorScheme.onError;
        break;
    }

    final child = isLoading
        ? SizedBox(
            height: AppDimensions.iconSizeSM,
            width: AppDimensions.iconSizeSM,
            child: CircularProgressIndicator(
              color: foregroundColor,
              strokeWidth: 2.5,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconSizeSM),
                const SizedBox(width: AppDimensions.spacingSM),
              ],
              if (isFullWidth)
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1))
              else
                Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          );

    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: variant == AppButtonVariant.primary || variant == AppButtonVariant.danger 
          ? AppDimensions.elevationSM 
          : AppDimensions.elevationNone,
      shadowColor: Colors.transparent, // Minimalist look
      minimumSize: const Size(AppDimensions.buttonHeight, AppDimensions.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radius),
        side: side ?? BorderSide.none,
      ),
      disabledBackgroundColor: backgroundColor.withValues(alpha: 0.12),
      disabledForegroundColor: foregroundColor.withValues(alpha: 0.38),
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

/// A small icon button used in product cards, etc.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = AppDimensions.buttonHeight, // Ensure minimum 48x48
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size < AppDimensions.buttonHeight ? AppDimensions.buttonHeight : size;
    final theme = Theme.of(context);

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: onPressed == null 
            ? theme.disabledColor.withValues(alpha: 0.1) 
            : backgroundColor ?? theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          child: Icon(
            icon,
            color: onPressed == null
                ? theme.disabledColor
                : color ?? theme.colorScheme.onPrimary,
            size: AppDimensions.iconSize,
          ),
        ),
      ),
    );
  }
}


