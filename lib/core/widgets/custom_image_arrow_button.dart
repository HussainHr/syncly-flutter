import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/constants/app_dimensions.dart';

class CustomImageArrowButton extends StatelessWidget {
  final String title;
  final String? imageIcon;
  final double? fontSize;
  final Color? color;
  final VoidCallback onTap;

  const CustomImageArrowButton({
    super.key,
    required this.title,
    required this.onTap,
    this.imageIcon,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: color ?? AppColors.lightBlueColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 2),
            if (imageIcon != null)
              Image.asset(imageIcon!, height: 25, width: 25),
            
            const SizedBox(width: 10),

            // Title Text
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize ?? 15,
                  color: Colors.black87,
                ),
              ),
            ),

            // Arrow Icon
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.blackColor),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

