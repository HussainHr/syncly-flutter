import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';

class CustomGradientButton extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final double height;
  final double width;
  final double? elevation;
  final Color? elevatedButtonColor;
  final BorderRadius? borderRadius;
  final void Function()? onPressed; // Made nullable for disable
  final Widget? widget;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;
  final RoundedRectangleBorder? shapeColor;
  final Color? foregroundColor;
  final String? rightIcon;
  final String? leftIcon;
  final IconData? rightIconData; // Added IconData support
  final IconData? leftIconData; // Added IconData support
  final bool hasIcon;
  final bool hasLeftIcon;
  final bool isGradient; // New: Enable gradient
  final bool isDisabled; // New: Disable state
  final bool isSpaceBetween; // New: Disable state
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? iconSize;
  final Color? disabledColor;
  final Color? disabledTextColor;

  const CustomGradientButton({
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
    this.rightIcon,
    this.rightIconData,
    this.fontWeight,
    this.fontSize,
    this.color = AppColors.primaryColor,
    this.isGradient = false,
    this.isDisabled = false,
    this.iconSize = 20,
    this.disabledColor,
    this.disabledTextColor,
    this.hasLeftIcon = false,
    this.isSpaceBetween = false,
    this.leftIcon,
    this.leftIconData,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if button should be disabled
    final bool isButtonDisabled = isDisabled || onPressed == null;

    return Material(
      color: Colors.transparent,
      elevation: isButtonDisabled ? 0 : (elevation ?? 5),
      borderRadius: borderRadius ?? BorderRadius.circular(50),
      child: InkWell(
        onTap: isButtonDisabled ? null : onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(50),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(50),
            border: border,

            gradient: isGradient
                ? LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: isButtonDisabled
                  ? [
                AppColors.secondaryColor.withValues(alpha: 0.35),
                AppColors.primaryColor.withValues(alpha: 0.35),
              ]
                  : [
                AppColors.secondaryColor,
                AppColors.primaryColor,
              ],
            )
                : null,
            color: isGradient
                ? null
                : (isButtonDisabled
                ? (disabledColor ?? Colors.grey)
                : (color ?? AppColors.primaryColor)),
          ),
          alignment: alignment ?? Alignment.center,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: widget ??
              Row(
                mainAxisAlignment: isSpaceBetween
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (hasLeftIcon) ...[
                    if (leftIcon != null)
                    // You might want to use SvgPicture.asset here if it's an SVG path
                    // For now keeping it simple or assuming Image.asset if it's a path
                      Image.asset(
                        leftIcon!,
                        color: isButtonDisabled
                            ? (disabledTextColor ?? Colors.white70)
                            : (textColor ?? Colors.white),
                        height: iconSize,
                        width: iconSize,
                      )
                    else if (leftIconData != null)
                      Icon(
                        leftIconData,
                        color: isButtonDisabled
                            ? (disabledTextColor ?? Colors.white70)
                            : (textColor ?? Colors.white),
                        size: iconSize,
                      ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isButtonDisabled
                          ? (disabledTextColor ?? Colors.white70)
                          : (textColor ?? Colors.white),
                      fontSize: fontSize ?? 16,
                      fontWeight: fontWeight ?? FontWeight.w600,
                    ),
                  ),
                  if (hasIcon) ...[
                    const SizedBox(width: 8),
                    if (rightIcon != null)
                      Image.asset(
                        rightIcon!,
                        color: isButtonDisabled
                            ? (disabledTextColor ?? Colors.white70)
                            : (textColor ?? Colors.white),
                        height: iconSize,
                        width: iconSize,
                      )
                    else if (rightIconData != null)
                      Icon(
                        rightIconData,
                        color: isButtonDisabled
                            ? (disabledTextColor ?? Colors.white70)
                            : (textColor ?? Colors.white),
                        size: iconSize,
                      ),
                  ],
                ],
              ),
        ),
      ),
    );
  }
}