import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const AppShimmer(width: 200, height: 32),
          const SizedBox(height: 24),
          // Chart Placeholder
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppShimmer(width: 100, height: 20),
                    AppShimmer(width: 80, height: 32, borderRadius: 16),
                  ],
                ),
                SizedBox(height: 32),
                Expanded(child: AppShimmer(width: double.infinity, height: double.infinity)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stat Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    AppShimmer(width: 24, height: 24),
                    SizedBox(height: 12),
                    AppShimmer(width: 80, height: 14),
                    SizedBox(height: 8),
                    AppShimmer(width: 60, height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
