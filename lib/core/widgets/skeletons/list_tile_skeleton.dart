import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class ListTileSkeleton extends StatelessWidget {
  final bool showSubtitle;
  final bool showTrailing;
  final double leadingSize;

  const ListTileSkeleton({
    super.key,
    this.showSubtitle = true,
    this.showTrailing = true,
    this.leadingSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AppShimmer(
            width: leadingSize,
            height: leadingSize,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppShimmer(width: 180, height: 14, borderRadius: 10),
                if (showSubtitle) ...[
                  const SizedBox(height: 8),
                  AppShimmer(
                    width: MediaQuery.sizeOf(context).width * 0.45,
                    height: 12,
                    borderRadius: 10,
                  ),
                ],
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const AppShimmer(width: 42, height: 14, borderRadius: 10),
          ],
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showSubtitle;
  final bool showTrailing;

  const ListSkeleton({
    super.key,
    this.itemCount = 8,
    this.showSubtitle = true,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => ListTileSkeleton(
        showSubtitle: showSubtitle,
        showTrailing: showTrailing,
      ),
    );
  }
}

