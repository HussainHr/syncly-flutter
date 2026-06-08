import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';

// Alternative version with more customization options
class GradientText extends StatelessWidget {
  final String title;
  final FontWeight fontWeight;
  final double fontSize;
  final Gradient? gradient;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? height;

  const GradientText({
    super.key,
    required this.title,
    required this.fontWeight,
    required this.fontSize,
    this.gradient,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily,
    this.fontStyle,
    this.letterSpacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Default gradient if none provided
    const defaultGradient = LinearGradient(
      colors: [AppColors.primaryColor, AppColors.secondaryColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => (gradient ?? defaultGradient).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        title,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
          height: height,
          color: Colors.white,
        ),
      ),
    );
  }
}
