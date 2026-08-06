import 'dart:convert';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final String logoUrl;
  final double height;
  final double? width;
  final BoxFit fit;

  const AppLogo({
    super.key,
    required this.logoUrl,
    this.height = 64,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.startsWith('data:image')) {
      final base64Str = logoUrl.split(',').last;
      return Image.memory(
        base64Decode(base64Str),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, stack) => Icon(Icons.store, size: height),
      );
    } else {
      return Image.network(
        logoUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (ctx, err, stack) => Icon(Icons.store, size: height),
      );
    }
  }
}
