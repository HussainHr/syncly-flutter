import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class PollCardSkeleton extends StatelessWidget {
  const PollCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const AppShimmer(width: 40, height: 40, shape: BoxShape.circle),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 120, height: 14),
                  SizedBox(height: 6),
                  AppShimmer(width: 80, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Question
          const AppShimmer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          const AppShimmer(width: 200, height: 16),
          const SizedBox(height: 16),
          // Content (Image or Options)
          const AppShimmer(
            width: double.infinity,
            height: 200,
            borderRadius: 12,
          ),
          const SizedBox(height: 16),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppShimmer(width: 60, height: 24),
              AppShimmer(width: 60, height: 24),
              AppShimmer(width: 60, height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
