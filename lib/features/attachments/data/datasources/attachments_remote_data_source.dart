import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncly/firebase_options.dart';

class AttachmentsRemoteDataSource {
  final FirebaseStorage _storage;

  AttachmentsRemoteDataSource({FirebaseStorage? storage})
      : _storage = storage ??
            FirebaseStorage.instanceFor(
              bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
            );

  /// Uploads a file and emits progress [0..1].
  Stream<({double progress, UploadTask task})> upload({
    required String path,
    required String storagePath,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async* {
    final ref = _storage.ref(storagePath);
    final file = File(path);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
    );
    final task = ref.putFile(file, metadata);

    yield (progress: 0, task: task);

    await for (final snap in task.snapshotEvents) {
      final total = snap.totalBytes == 0 ? 1 : snap.totalBytes;
      final p = snap.bytesTransferred / total;
      yield (progress: p.clamp(0, 1), task: task);
    }
  }

  Future<String> getDownloadUrl(UploadTask task) async {
    final snap = await task;
    return snap.ref.getDownloadURL();
  }
}

