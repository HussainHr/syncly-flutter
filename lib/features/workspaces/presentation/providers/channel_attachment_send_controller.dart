import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'channel_chat_providers.dart';

@immutable
class ChannelAttachmentSendState {
  final bool sending;
  final double progress;
  final String? error;

  const ChannelAttachmentSendState({
    required this.sending,
    required this.progress,
    this.error,
  });

  const ChannelAttachmentSendState.idle()
      : sending = false,
        progress = 0,
        error = null;

  ChannelAttachmentSendState copyWith({
    bool? sending,
    double? progress,
    String? error,
  }) {
    return ChannelAttachmentSendState(
      sending: sending ?? this.sending,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

final channelAttachmentSendControllerProvider =
    StateNotifierProvider<ChannelAttachmentSendController, ChannelAttachmentSendState>((ref) {
  return ChannelAttachmentSendController(ref);
});

class ChannelAttachmentSendController extends StateNotifier<ChannelAttachmentSendState> {
  final Ref _ref;

  ChannelAttachmentSendController(this._ref) : super(const ChannelAttachmentSendState.idle());

  Future<String?> _compressImageIfNeeded(String path) async {
    try {
      final ext = path.toLowerCase();
      final isImage =
          ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png');
      if (!isImage) return path;

      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/ch_img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final res = await FlutterImageCompress.compressAndGetFile(
        path,
        out.path,
        quality: 82,
        format: CompressFormat.jpeg,
      );
      return res?.path ?? path;
    } catch (_) {
      return path;
    }
  }

  Future<void> sendImage({
    required String workspaceId,
    required String channelId,
    required String filePath,
    String? caption,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    state = state.copyWith(sending: true, progress: 0, error: null);
    try {
      final path = await _compressImageIfNeeded(filePath) ?? filePath;
      final bytes = await File(path).readAsBytes();
      if (bytes.lengthInBytes > 700 * 1024) {
        throw Exception('Image is too large. Please choose a smaller image.');
      }
      final base64 = base64Encode(bytes);

      state = state.copyWith(progress: 1);
      await _ref.read(channelChatRepositoryProvider).sendImageMessage(
            workspaceId: workspaceId,
            channelId: channelId,
            myUid: me.uid,
            imageBase64: base64,
            caption: caption,
            sizeBytes: bytes.lengthInBytes,
          );

      state = const ChannelAttachmentSendState.idle();
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }
}
