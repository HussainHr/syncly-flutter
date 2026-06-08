import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/features/auth/presentation/screens/register_page.dart';
import 'package:syncly/features/splash/splash_page.dart';
import 'package:syncly/features/auth/presentation/screens/login_page.dart';
import 'package:syncly/features/auth/presentation/screens/forgot_password_page.dart';
import 'package:syncly/features/home/home_page.dart';
import 'package:syncly/features/chats/presentation/screens/chat_room_page.dart';
import 'package:syncly/features/users/presentation/screens/edit_profile_page.dart';
import 'package:syncly/features/users/presentation/screens/my_profile_page.dart';
import 'package:syncly/features/users/presentation/screens/user_profile_page.dart';
import 'package:syncly/features/users/presentation/screens/users_page.dart';
import 'package:syncly/features/settings/presentation/screens/settings_page.dart';
import 'package:syncly/core/repositories/auth_repository.dart';

// ✅ Provider to track if app is initializing
final appInitializingProvider = StateProvider<bool>((ref) => true);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final isInitializing = ref.watch(appInitializingProvider);

  return GoRouter(
    initialLocation: '/splash', // ✅ Start with splash
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      authRepository.authTokenStateChanges(),
    ),
    redirect: (context, state) async {
      final path = state.uri.toString();

      // ✅ Always show splash on first load
      if (path == '/splash') {
        return null;
      }

      // ✅ Show splash while initializing
      if (isInitializing) {
        return '/splash';
      }

      final isAuthPage =
          path.startsWith('/login') ||
          path.startsWith('/register') ||
          path.startsWith('/forgot-password') ||
          path.startsWith('/otp-verification') ||
          path.startsWith('/reset-password');
      final isLoggedIn =
          await authRepository.isAuthenticated() ||
          authRepository.currentUser != null;

      if (!isLoggedIn && !isAuthPage) return '/login';
      if (isLoggedIn && isAuthPage) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/users', builder: (context, state) => const UsersPage()),
      GoRoute(
        path: '/users/:uid',
        builder: (context, state) => UserProfilePage(
          uid: state.pathParameters['uid']!,
        ),
      ),
      GoRoute(path: '/me', builder: (context, state) => const MyProfilePage()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfilePage()),
      GoRoute(
        path: '/chats/:chatId',
        builder: (context, state) => ChatRoomPage(
          chatId: state.pathParameters['chatId']!,
          otherUid: state.uri.queryParameters['otherUid'] ?? '',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(embedded: false),
      ),

    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _streamSubscription = stream.listen(
      (_) => notifyListeners(),
      onError: (error) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _streamSubscription;

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
