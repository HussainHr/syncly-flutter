import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';

class BottomNavItem extends StatelessWidget {
  final String iconName;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BottomNavItem({
    required this.iconName,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            height: 40,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: AppDimensions.widgetMarginVerticalSmalls,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(360),
              color: selected ? AppColors.blackLight : Colors.transparent,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SvgPicture.asset(
                iconName,
                key: ValueKey(selected),
                colorFilter: ColorFilter.mode(
                  selected ? AppColors.primaryColor : AppColors.borderMedium,
                  BlendMode.srcIn,
                ),
                semanticsLabel: 'Navigation icon',
              ),
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: selected ? AppColors.primaryColor : AppColors.borderMedium, fontWeight: FontWeight.w500),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
