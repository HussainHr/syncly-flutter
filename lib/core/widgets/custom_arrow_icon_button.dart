import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';

class CustomArrowIconButton extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final double height;
  final double width;
  final double? elevation;
  final Color? elevatedButtonColor;
  final BorderRadius? borderRadius;
  final void Function() onPressed;
  final Widget? widget;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;
  final RoundedRectangleBorder? shapeColor;
  final Color? foregroundColor;
  final String? rightIcon; // Asset path for icon/image
  final String? leftIcon; // New: Left side icon
  final bool hasIcon;
  final bool hasLeftIcon; // New: Condition for left icon
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? iconSize; // New: Custom icon size
  final Widget? customIcon; // New: Custom widget as icon
  final Color? iconColor; // New: Icon color for SVG/Icon widgets
  final MainAxisAlignment rowAlignment; // New: Control row alignment

  const CustomArrowIconButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.widget,
    this.textColor = Colors.white,
    this.height = 54,
    this.shapeColor,
    this.border,
    this.elevation,
    this.foregroundColor,
    required this.width,
    this.elevatedButtonColor,
    this.padding,
    this.alignment,
    this.borderRadius,
    this.hasIcon = false,
    this.hasLeftIcon = false, // Default false
    this.rightIcon,
    this.leftIcon,
    this.fontWeight,
    this.fontSize,
    this.iconSize = 20, // Default icon size
    this.customIcon,
    this.iconColor,
    this.rowAlignment = MainAxisAlignment.center,
    this.color = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: elevation ?? 5,
        backgroundColor: elevatedButtonColor ?? color,
        foregroundColor: foregroundColor ?? Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(50),
        ),
      ),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: border,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: rowAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon (conditionally shown)
            if (hasLeftIcon && leftIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildIcon(leftIcon!, isLeft: true),
              ),

            // Custom icon widget (if provided)
            if (customIcon != null && !hasLeftIcon && !hasIcon)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: customIcon!,
              ),

            // Text
            Text(
              text,
              style: TextStyle(
                fontWeight: fontWeight,
                fontSize: fontSize,
                color: textColor ?? AppColors.whiteColor,
              ),
            ),

            const SizedBox(width: 8),

            // Right Icon (conditionally shown)
            if (hasIcon && rightIcon != null)
              _buildIcon(rightIcon!, isLeft: false),

            // If no icon but hasIcon is true (fallback)
            if (hasIcon && rightIcon == null && customIcon == null)
              Icon(
                Icons.arrow_forward_ios,
                size: iconSize,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build icon from asset or use default
  Widget _buildIcon(String iconPath, {bool isLeft = false}) {
    if (iconPath.contains('.svg')) {
      return SvgPicture.asset(
        iconPath,
        height: iconSize,
        width: iconSize,
        color: iconColor,
      );
    } else if (iconPath.startsWith('Icons.')) {
      // For Material Icons
      return Icon(
        Icons.arrow_forward_ios,
        size: iconSize,
        color: iconColor,
      );
    } else {
      // For image assets (PNG, JPG, etc.)
      return Image.asset(
        iconPath,
        height: iconSize,
        width: iconSize,
        color: iconColor,
      );
    }
  }
}
