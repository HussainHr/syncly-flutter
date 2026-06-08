import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/spacings/space.dart';
import 'package:syncly/features/bottom_bar/presentation/providers/state/bottom_bar_notifier.dart';

class CustomBottomNavigationBar extends ConsumerWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(bottomBarControllerProvider);
    final notifier = ref.read(bottomBarControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: controller.selectedIndex == 0,
                onTap: () => notifier.onItemTapped(0),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.leaderboard,
                label: "LeaderBoard",
                isSelected: controller.selectedIndex == 1,
                onTap: () => notifier.onItemTapped(1),
              ),
              horizontalSpacing(65),
              // _buildNavItem(
              //   context: context,
              //   icon: Icons.add,
              //   label: "Create",
              //   isSelected: controller.selectedIndex == 2,
              //   onTap: () => notifier.onItemTapped(2),
              // ),
              _buildNavItem(
                context: context,
                icon: Icons.analytics,
                label: "Analytics",
                isSelected: controller.selectedIndex == 3,
                onTap: () => notifier.onItemTapped(3),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.account_circle_rounded,
                label: "Profile",
                isSelected: controller.selectedIndex == 4,
                onTap: () => notifier.onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animated circular background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 70,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
