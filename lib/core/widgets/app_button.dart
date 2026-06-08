import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';
import 'package:syncly/core/spacings/space.dart';

class AppButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Function onClick;
  late final bool isNonFill;
  late final EdgeInsets margin;
  late final Color color;
  late final Color titleColor;
  late final Color borderColor;
  late final double width;
  late final double height;
  late final double fontSize;
  late final Color iconColor;
  final bool? isDisabled;
  final double? elevation;

  AppButton({
    super.key,
    required this.title,
    required this.onClick,
    double? width,
    double? height,
    double? fontSize,
    this.icon,
    EdgeInsets? margin,
    bool? isNonFill,
    Color? color,
    Color? titleColor,
    Color? borderColor,
    Color? iconColor,
    this.isDisabled,
    this.elevation,
  }) {
    this.margin = margin ?? AppDimensions.appMarginHorizontal;
    this.width = width ?? double.infinity;
    this.height = height ?? AppDimensions.appButtonHeight;
    this.fontSize = fontSize ?? AppDimensions.fontButtonSize;
    this.isNonFill = isNonFill ?? false;
    this.color = color ?? AppColors.primaryColor;
    this.titleColor = titleColor ?? AppColors.blackColor;
    this.borderColor = borderColor ?? AppColors.primaryColor;
    this.iconColor = iconColor ?? AppColors.whiteColor;
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled ?? false;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.appButtonRadius),
      ),
      child: MaterialButton(
        disabledColor: AppColors.greyLight,
        onPressed: disabled ? null : () => onClick(),
        elevation: 0,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.appButtonRadius),
          side: BorderSide(
            color: disabled ? AppColors.greyColor : borderColor,
            width: 1,
          ),
        ),
        color: disabled
            ? AppColors.primaryColor
            : (isNonFill ? AppColors.whiteColor : color),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: disabled ? AppColors.greyColor : iconColor,
                  size: AppDimensions.appButtonIconSize,
                ),
                horizontalSpacing(8),
              ],
              Text(title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: disabled ? AppColors.greyColor : titleColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

