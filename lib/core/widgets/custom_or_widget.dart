import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';

class DividerWithText extends StatelessWidget {
  final String text;
  final Color? dividerColor;
  final Color? textBgColor;
  final TextStyle? textStyle;
  final double thickness;
  final EdgeInsetsGeometry padding;

  const DividerWithText({
    super.key,
    required this.text,
    this.dividerColor,
    this.textBgColor,
    this.textStyle,
    this.thickness = 1.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dividerColor ?? AppColors.boarderColor,
            thickness: thickness,
          ),
        ),

        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: textBgColor ?? AppColors.boarderColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  color: AppColors.greyLight400,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
          ),
        ),

        Expanded(
          child: Divider(
            color: dividerColor ?? AppColors.boarderColor,
            thickness: thickness,
          ),
        ),
      ],
    );
  }
}

