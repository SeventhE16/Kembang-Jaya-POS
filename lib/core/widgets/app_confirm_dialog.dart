import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_button.dart';

/// Shows a generic confirmation dialog
void showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  required VoidCallback onConfirm,
  bool isDestructive = false,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDestructive ? Icons.warning_rounded : Icons.help_outline_rounded,
              size: 48,
              color: isDestructive ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    isPrimary: false,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48, // Match standard button height if AppButton specifies it
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(confirmLabel),
                    ),
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
