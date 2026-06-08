import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/providers/auth_provider.dart';
import 'package:syncly/features/users/domain/entities/app_user.dart';
import 'package:syncly/features/users/domain/repositories/users_repository.dart';
import 'package:syncly/features/users/presentation/providers/users_providers.dart';

class UsersListState {
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String query;
  final List<AppUser> users;
  final bool hasMore;

  const UsersListState({
    required this.loading,
    required this.loadingMore,
    required this.query,
    required this.users,
    required this.hasMore,
    this.error,
  });

  const UsersListState.initial()
      : loading = true,
        loadingMore = false,
        error = null,
        query = '',
        users = const [],
        hasMore = true;

  UsersListState copyWith({
    bool? loading,
    bool? loadingMore,
    String? error,
    String? query,
    List<AppUser>? users,
    bool? hasMore,
  }) {
    return UsersListState(
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      query: query ?? this.query,
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final usersListControllerProvider =
    StateNotifierProvider<UsersListController, UsersListState>((ref) {
  final repo = ref.watch(usersRepositoryProvider);
  final me = ref.watch(currentUserProvider);
  return UsersListController(repo, currentUid: me?.uid)..refresh();
});

class UsersListController extends StateNotifier<UsersListState> {
  final UsersRepository _repo;
  final String? _currentUid;
  static const int _pageSize = 25;

  String? _cursorUid;

  UsersListController(this._repo, {required String? currentUid})
      : _currentUid = currentUid,
        super(const UsersListState.initial());

  Future<void> refresh({String? query}) async {
    final q = query ?? state.query;
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      error: null,
      query: q,
      users: const [],
      hasMore: true,
    );
    _cursorUid = null;
    await _loadMoreInternal();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true, error: null);
    await _loadMoreInternal();
  }

  Future<void> _loadMoreInternal() async {
    try {
      final page = await _repo.getUsersPage(
        limit: _pageSize,
        searchTerm: state.query,
        startAfterUid: _cursorUid,
      );

      final filtered = _currentUid == null
          ? page
          : page.where((u) => u.uid != _currentUid).toList(growable: false);

      final nextUsers = [...state.users, ...filtered];
      final nextCursor = page.isEmpty ? _cursorUid : page.last.uid;
      final hasMore = page.length >= _pageSize;

      _cursorUid = nextCursor;
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: null,
        users: nextUsers,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString(),
      );
    }
  }
}

