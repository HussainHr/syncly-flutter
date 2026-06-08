import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/friends/data/datasources/friends_remote_data_source.dart';
import 'package:syncly/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:syncly/features/friends/domain/repositories/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepositoryImpl(FriendsRemoteDataSource());
});

