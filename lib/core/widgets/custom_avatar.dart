import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncly/core/constants/app_colors.dart';

class CustomAvatar extends StatelessWidget {
  const CustomAvatar({
    super.key,
    required this.height,
    required this.width,
    required this.image,
    this.name,
    this.base64,
    this.network = false,
    this.file = false,
  });

  final double height, width;
  final String image;
  final String? name;
  final String? base64;
  final bool network, file;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    final b64 = (base64 ?? '').trim();
    if (b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }

    final shouldShowInitials = bytes == null &&
        !file &&
        !(network && image.trim().isNotEmpty) &&
        image.trim().isEmpty;

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: shouldShowInitials
            ? _InitialsAvatar(
                name: name ?? '',
                size: height,
              )
            : bytes != null
            ? Image.memory(
                bytes,
                height: height,
                width: width,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _InitialsAvatar(name: name ?? '', size: height),
              )
            : file
            ? Image.file(
                File(image),
                height: height,
                width: width,
                fit: BoxFit.cover,
              )
            : network
                ? CachedNetworkImage(
                    height: height,
                    width: width,
                    imageUrl: image,
                    fit: BoxFit.cover,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => CircularProgressIndicator(
                      value: downloadProgress.progress,
                      color: AppColors.primaryColor,
                      strokeWidth: 3,
                    ),
                    errorWidget: (context, url, error) =>
                        _InitialsAvatar(name: name ?? '', size: height),
                  )
                : Image.asset(
                    image, // Assuming image is asset path if not network/file
                    fit: BoxFit.cover,
                    height: height,
                    width: width,
                    errorBuilder: (context, error, stackTrace) =>
                        _InitialsAvatar(name: name ?? '', size: height),
                  ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialsAvatar({required this.name, required this.size});

  String _initials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      final a = w.characters.first.toUpperCase();
      final b = w.characters.length >= 2 ? w.characters.elementAt(1).toUpperCase() : '';
      return (a + b).trim();
    }
    final a = parts.first.characters.first.toUpperCase();
    final b = parts[1].characters.first.toUpperCase();
    return '$a$b';
  }

  Color _bg(BuildContext context) {
    final s = name.trim().isEmpty ? 'user' : name.trim().toLowerCase();
    final hash = s.codeUnits.fold<int>(0, (p, c) => (p * 31 + c) & 0x7fffffff);
    final palette = <Color>[
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFF8E24AA),
      const Color(0xFFF4511E),
      const Color(0xFF00897B),
      const Color(0xFF3949AB),
      const Color(0xFF6D4C41),
    ];
    final c = palette[hash % palette.length];
    return c.withValues(alpha: 0.92);
  }

  @override
  Widget build(BuildContext context) {
    final text = _initials();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg(context),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.34,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

