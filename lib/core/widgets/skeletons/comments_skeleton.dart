import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class CommentsSkeleton extends StatelessWidget {
  final int itemCount;

  const CommentsSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmer(width: 40, height: 40, shape: BoxShape.circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 100, height: 14),
                  SizedBox(height: 6),
                  AppShimmer(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  AppShimmer(width: 150, height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
