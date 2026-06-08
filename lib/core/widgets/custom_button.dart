import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';

class CustomButton extends StatelessWidget {
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
  final BorderSide? border;
  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;
  final RoundedRectangleBorder? shapeColor;
  final Color? foregroundColor;
  final String? rightIcon;
  final bool hasIcon;
  final FontWeight? fontWeight;
  final double? fontSize;
  final bool isLoading;

  const CustomButton({
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
    this.fontWeight,
    this.fontSize,
    this.isLoading = false,
    this.color = AppColors.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? () {} : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: elevation ?? 0,
        // shadowColor: Colors.grey.shade700,
        backgroundColor: elevatedButtonColor ?? color,
        foregroundColor: foregroundColor ?? Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
      ),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(50),
          border: border != null ? Border.fromBorderSide(border!) : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: textColor ?? Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: fontWeight ?? FontWeight.w600,
                      fontSize: fontSize ?? 16,
                      color: textColor ?? AppColors.whiteColor,
                    ),
                  ),
                  if (hasIcon) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}
