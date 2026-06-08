import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          const Center(
            child: AppShimmer(width: 100, height: 100, shape: BoxShape.circle),
          ),
          const SizedBox(height: 16),
          // Name
          const Center(child: AppShimmer(width: 150, height: 24)),
          const SizedBox(height: 8),
          // Bio
          const Center(child: AppShimmer(width: 250, height: 14)),
          const SizedBox(height: 24),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              AppShimmer(width: 80, height: 60),
              AppShimmer(width: 80, height: 60),
              AppShimmer(width: 80, height: 60),
            ],
          ),
          const SizedBox(height: 32),
          // Tab Bar
          const AppShimmer(width: double.infinity, height: 48, borderRadius: 24),
          const SizedBox(height: 24),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const AppShimmer(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 12,
              );
            },
          ),
        ],
      ),
    );
  }
}
