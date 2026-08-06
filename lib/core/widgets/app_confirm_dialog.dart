import 'package:flutter/material.dart';
import 'app_button.dart';

import '../constants/app_dimensions.dart';

/// Shows a generic confirmation dialog
void showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Konfirmasi',
  String cancelLabel = 'Batal',
  required VoidCallback onConfirm,
  bool isDestructive = false,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radius)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDestructive ? Icons.warning_rounded : Icons.help_outline_rounded,
              size: 48,
              color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSM),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
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

/// Shows a delete specific confirmation dialog
void showDeleteDialog(
  BuildContext context, {
  required String itemName,
  required VoidCallback onConfirm,
}) {
  showConfirmDialog(
    context,
    title: 'Hapus $itemName?',
    message: 'Data yang dihapus tidak dapat dikembalikan.',
    confirmLabel: 'Hapus',
    isDestructive: true,
    onConfirm: onConfirm,
  );
}



