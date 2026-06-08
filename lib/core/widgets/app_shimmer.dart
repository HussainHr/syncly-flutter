import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class AppShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBase =
        baseColor ?? (isDark ? cs.surfaceContainerHighest : Colors.grey[300]);
    final effectiveHighlight =
        highlightColor ?? (isDark ? cs.onSurface.withValues(alpha: 0.10) : Colors.white);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : BorderRadius.zero,
        child: Shimmer(
          duration: const Duration(seconds: 2),
          interval: const Duration(milliseconds: 500),
          color: effectiveHighlight,
          colorOpacity: 0.3,
          enabled: true,
          direction: const ShimmerDirection.fromLTRB(),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBase,
              borderRadius: shape == BoxShape.rectangle
                  ? BorderRadius.circular(borderRadius)
                  : null,
              shape: shape,
            ),
          ),
        ),
      ),
    );
  }
}
