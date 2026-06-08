import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncly/core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subTitle;
  final bool hasFilterButton;
  final bool hasMoreButton;
  final bool hasBackButton;
  final bool hasSubtitle;
  final bool automaticBackButton;
  late final Color bgColor;
  late final Color fgColor; // Ensure fgColor is always initialized
  late final Color color;

  /// false → black status bar icons (default)
  /// true  → white status bar icons
  final bool whiteStatusBarIcons;

  final VoidCallback? onFilterTaped;
  final VoidCallback? onBackButtonTapped;
  final VoidCallback? onMoreBUttonTaped;
  final double? appBarHeight;

  CustomAppBar({
    super.key,
    required this.title,
    this.subTitle,
    Color? bgColor,
    Color? color,
    this.whiteStatusBarIcons = false,
    this.fgColor = const Color(0xFF000000), // Defaulting fgColor to black if null
    this.hasFilterButton = false,
    this.hasMoreButton = false,
    this.hasBackButton = true,
    this.hasSubtitle = false,
    this.automaticBackButton = false,
    this.onFilterTaped,
    this.onBackButtonTapped,
    this.onMoreBUttonTaped,
    this.appBarHeight
  }) {
    this.bgColor = bgColor ?? AppColors.surfaceColor;
    this.color = color ?? AppColors.whiteColor;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: fgColor,
      // Ensure fgColor is used here
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      // 🔒 STATUS BAR STYLE (DEFAULT = BLACK ICONS)
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        whiteStatusBarIcons ? Brightness.light : Brightness.dark,
        statusBarBrightness:
        whiteStatusBarIcons ? Brightness.dark : Brightness.light,
      ),

      actionsIconTheme: IconThemeData(color: color),
      automaticallyImplyLeading: automaticBackButton,
      centerTitle: true,
      leading: hasBackButton
          ? IconButton(
              onPressed: onBackButtonTapped ?? () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.arrow_back, color: AppColors.blackColor),
            )
          : null,
      title: hasSubtitle ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.blackColor, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if(hasSubtitle)...[
            Text(
              subTitle.toString(),
              style: const TextStyle(color: AppColors.lightBlueColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ]
        ],
      ) : Text(
        title,
        style: const TextStyle(color: AppColors.blackColor, fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(appBarHeight ?? kToolbarHeight);
}
