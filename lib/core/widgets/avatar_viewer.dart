import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncly/core/widgets/custom_avatar.dart';

Future<void> showAvatarViewer(
  BuildContext context, {
  required String name,
  String? photoUrl,
  String? photoBase64,
}) async {
  final url = (photoUrl ?? '').trim();
  final b64 = (photoBase64 ?? '').trim();

  Uint8List? bytes;
  if (b64.isNotEmpty) {
    try {
      bytes = base64Decode(b64);
    } catch (_) {
      bytes = null;
    }
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: bytes != null
                        ? Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                          )
                        : (url.isNotEmpty
                            ? Image.network(url, fit: BoxFit.contain)
                            : Center(
                                child: CustomAvatar(
                                  height: 140,
                                  width: 140,
                                  name: name,
                                  image: '',
                                  network: false,
                                ),
                              )),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

