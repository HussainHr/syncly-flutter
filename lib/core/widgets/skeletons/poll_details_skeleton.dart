import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';
import 'package:syncly/core/widgets/skeletons/poll_card_skeleton.dart';
import 'package:syncly/core/widgets/skeletons/comments_skeleton.dart';

class PollDetailsSkeleton extends StatelessWidget {
  const PollDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PollCardSkeleton(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppShimmer(width: 120, height: 24), // "Comments" header
                const SizedBox(height: 16),
                // Comments list
                const CommentsSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
