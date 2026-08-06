import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: Theme.of(context).cardTheme.shape is RoundedRectangleBorder 
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius?
            : null,
        child: content,
      );
    }

    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12.0),
      color: color,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
