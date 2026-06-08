import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/chats/data/datasources/chat_remote_data_source.dart';
import 'package:syncly/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:syncly/features/chats/domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ChatRemoteDataSource());
});

