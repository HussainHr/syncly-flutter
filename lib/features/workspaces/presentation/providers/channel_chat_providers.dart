import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/channel_messages_remote_data_source.dart';
import '../../data/repositories/channel_chat_repository_impl.dart';
import '../../domain/repositories/channel_chat_repository.dart';

final channelMessagesRemoteDataSourceProvider =
    Provider<ChannelMessagesRemoteDataSource>((ref) {
  return ChannelMessagesRemoteDataSource(db: FirebaseFirestore.instance);
});

final channelChatRepositoryProvider = Provider<ChannelChatRepository>((ref) {
  return ChannelChatRepositoryImpl(ref.watch(channelMessagesRemoteDataSourceProvider));
});
