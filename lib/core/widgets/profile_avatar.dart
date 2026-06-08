import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double radius;
  final bool showBorder;
  final Color borderColor;
  final Widget? child;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider(imageUrl);
    final initials = _getInitials(fallbackText);

    return Container(
      decoration: showBorder
          ? BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: imageProvider == null
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
            : null,
        child: imageProvider == null
            ? Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        )
            : child,
      ),
    );
  }

  ImageProvider? _getImageProvider(String? url) {
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  String _getInitials(String? text) {
    if (text == null || text.isEmpty) return 'U';

    final parts = text.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return text[0].toUpperCase();
  }
}
