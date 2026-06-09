import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/workspaces_remote_data_source.dart';
import '../../data/repositories/workspaces_repository_impl.dart';
import '../../domain/repositories/workspaces_repository.dart';

final workspacesRemoteDataSourceProvider = Provider<WorkspacesRemoteDataSource>((ref) {
  return WorkspacesRemoteDataSource(db: FirebaseFirestore.instance);
});

final workspacesRepositoryProvider = Provider<WorkspacesRepository>((ref) {
  return WorkspacesRepositoryImpl(ref.watch(workspacesRemoteDataSourceProvider));
});
