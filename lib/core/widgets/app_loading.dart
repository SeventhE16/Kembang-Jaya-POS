import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import 'package:depot_kayu_app/core/extensions/context_colors.dart';

class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: context.colorPrimary,
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.colorTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: CircularProgressIndicator(
                color: context.colorPrimary,
              ),
            ),
          ),
      ],
    );
  }
}