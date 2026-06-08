import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.prefixIcon,
    this.height,
    this.width,
    this.textInputType,
    this.textInputAction,
    this.onChanged,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.filColor,
    this.labelTexColor,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.textAlignVertical,
    this.decoration,
    this.hintStyle,
    this.padding,
    this.borderRadius,
    this.borderSide,
    this.onTap,
    this.obscureText = false,
    this.readOnly = false,
    this.showDatePicker = false,
    this.validator,
  });

  final TextEditingController controller;
  final double? height, width;
  final Widget? prefixIcon;
  final Decoration? decoration;
  final int maxLines;
  final int? minLines;
  final String hintText;
  final String? labelText;
  final Color? filColor, labelTexColor;
  final Widget? suffixIcon;
  final TextInputType? textInputType;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? hintStyle;
  final bool obscureText;
  final bool readOnly;
  final bool showDatePicker;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BorderSide? borderSide;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: TextFormField(
        validator: validator,
        readOnly: readOnly,
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: textInputType,
        textAlignVertical: textAlignVertical,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.blackColor),
        onTap: readOnly ? onTap : null,
        decoration: InputDecoration(
          hintText: hintText,
          label: labelText != null ? Text(labelText.toString()) : null,
          labelStyle: TextStyle(
            color: AppColors.greyLight600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          contentPadding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          hintStyle:
              hintStyle ??
              TextStyle(
                color: AppColors.greyLight,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
          filled: true,
          fillColor: filColor ?? Colors.white,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            borderSide:
                borderSide ??
                const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            borderSide:
                borderSide ??
                const BorderSide(color: AppColors.borderColor, width: 1),
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            borderSide:
                borderSide ??
                const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}
