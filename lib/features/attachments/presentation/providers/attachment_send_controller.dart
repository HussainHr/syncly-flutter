import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../chats/presentation/providers/chat_providers.dart';

@immutable
class AttachmentSendState {
  final bool sending;
  final double progress;
  final String? error;

  const AttachmentSendState({
    required this.sending,
    required this.progress,
    this.error,
  });

  const AttachmentSendState.idle() : sending = false, progress = 0, error = null;

  AttachmentSendState copyWith({bool? sending, double? progress, String? error}) {
    return AttachmentSendState(
      sending: sending ?? this.sending,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

final attachmentSendControllerProvider =
StateNotifierProvider<AttachmentSendController, AttachmentSendState>((ref) {
  return AttachmentSendController(ref);
});

class AttachmentSendController extends StateNotifier<AttachmentSendState> {
  final Ref _ref;

  AttachmentSendController(this._ref) : super(const AttachmentSendState.idle());

  Future<String?> _compressImageIfNeeded(String path) async {
    try {
      final ext = path.toLowerCase();
      final isImage = ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png');
      if (!isImage) return path;

      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
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
    required String chatId,
    required String filePath,
    String? caption,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    state = state.copyWith(sending: true, progress: 0, error: null);
    try {
      final path = await _compressImageIfNeeded(filePath) ?? filePath;
      final bytes = await File(path).readAsBytes();
      // Firestore document limit ~1MB. Keep base64 payload safely below that.
      // 700KB raw bytes -> ~933KB base64.
      if (bytes.lengthInBytes > 700 * 1024) {
        throw Exception('Image is too large. Please choose a smaller image.');
      }
      final base64 = base64Encode(bytes);

      state = state.copyWith(progress: 1);
      await _ref.read(chatRepositoryProvider).sendImageMessage(
            chatId: chatId,
            myUid: me.uid,
            imageBase64: base64,
            caption: caption,
            sizeBytes: bytes.lengthInBytes,
            width: null,
            height: null,
            replyToMessageId: replyToMessageId,
            replyToSenderUid: replyToSenderUid,
            replyToText: replyToText,
            replyToType: replyToType,
            isForwarded: isForwarded,
            forwardedFromUid: forwardedFromUid,
          );

      state = const AttachmentSendState.idle();
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> sendFile({
    required String chatId,
    required String filePath,
    required String fileName,
    required int? sizeBytes,
    required String? mimeType,
    String? replyToMessageId,
    String? replyToSenderUid,
    String? replyToText,
    String? replyToType,
    bool isForwarded = false,
    String? forwardedFromUid,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    state = state.copyWith(sending: true, progress: 0, error: null);
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 700 * 1024) {
        throw Exception('File is too large for Firestore base64. Please use a smaller file.');
      }
      final base64 = base64Encode(bytes);
      state = state.copyWith(progress: 1);

      await _ref.read(chatRepositoryProvider).sendFileMessage(
            chatId: chatId,
            myUid: me.uid,
            fileBase64: base64,
            fileName: fileName,
            mimeType: mimeType,
            sizeBytes: bytes.lengthInBytes,
            replyToMessageId: replyToMessageId,
            replyToSenderUid: replyToSenderUid,
            replyToText: replyToText,
            replyToType: replyToType,
            isForwarded: isForwarded,
            forwardedFromUid: forwardedFromUid,
          );

      state = const AttachmentSendState.idle();
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }
}

