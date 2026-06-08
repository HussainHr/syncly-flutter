import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/app_shimmer.dart';

class ChatBubbleSkeletonList extends StatelessWidget {
  final int itemCount;

  const ChatBubbleSkeletonList({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        final isMe = i.isEven;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: _Bubble(isMe: isMe),
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isMe;
  const _Bubble({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final width = (isMe ? 0.62 : 0.52) * maxW;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            AppShimmer(width: width, height: 12, borderRadius: 10),
            const SizedBox(height: 8),
            AppShimmer(width: width * 0.78, height: 12, borderRadius: 10),
            const SizedBox(height: 10),
            AppShimmer(width: 52, height: 10, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

