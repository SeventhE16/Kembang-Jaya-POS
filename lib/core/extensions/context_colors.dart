import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension ContextColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get colorPrimary => isDarkMode ? DarkColors.primary : AppColors.primary;
  Color get colorPrimaryLight => isDarkMode ? DarkColors.primaryLight : AppColors.primaryLight;
  Color get colorPrimarySurface => isDarkMode ? DarkColors.primarySurface : AppColors.primarySurface;

  Color get colorBackground => isDarkMode ? DarkColors.background : AppColors.background;
  Color get colorSurface => isDarkMode ? DarkColors.surface : AppColors.surface;
  Color get colorSurfaceCard => isDarkMode ? DarkColors.surfaceCard : AppColors.surfaceCard;

  Color get colorTextPrimary => isDarkMode ? DarkColors.textPrimary : AppColors.textPrimary;
  Color get colorTextSecondary => isDarkMode ? DarkColors.textSecondary : AppColors.textSecondary;
  Color get colorTextHint => isDarkMode ? DarkColors.textHint : AppColors.textHint;

  Color get colorSuccess => isDarkMode ? DarkColors.success : AppColors.success;
  Color get colorSuccessBackground => isDarkMode ? DarkColors.successBackground : AppColors.successBackground;
  Color get colorError => isDarkMode ? DarkColors.error : AppColors.error;
  Color get colorErrorBackground => isDarkMode ? DarkColors.errorBackground : AppColors.errorBackground;
  Color get colorWarning => isDarkMode ? DarkColors.warning : AppColors.warning;

  Color get colorDivider => isDarkMode ? DarkColors.divider : AppColors.divider;
  Color get colorInputFill => isDarkMode ? DarkColors.inputFill : AppColors.inputFill;
  Color get colorIconLight => isDarkMode ? DarkColors.iconLight : AppColors.iconLight;
  Color get colorChipInactive => isDarkMode ? DarkColors.chipInactive : AppColors.chipInactive;
  Color get colorStockEmpty => isDarkMode ? DarkColors.stockEmpty : AppColors.stockEmpty;
  Color get colorBadgeJasa => isDarkMode ? DarkColors.badgeJasa : AppColors.badgeJasa;
}
