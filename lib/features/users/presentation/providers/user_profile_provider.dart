import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/users/domain/entities/app_user.dart';
import 'package:syncly/features/users/presentation/providers/users_providers.dart';

final userProfileProvider = FutureProvider.family<AppUser?, String>((ref, uid) {
  final repo = ref.watch(usersRepositoryProvider);
  return repo.getUserByUid(uid);
});

