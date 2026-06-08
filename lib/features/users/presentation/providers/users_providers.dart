import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/users/data/datasources/users_remote_data_source.dart';
import 'package:syncly/features/users/data/repositories/users_repository_impl.dart';
import 'package:syncly/features/users/domain/repositories/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepositoryImpl(UsersRemoteDataSource());
});

