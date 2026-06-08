import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncly/core/constants/app_asset_paths.dart';
import 'package:syncly/core/constants/app_colors.dart';
import 'package:syncly/core/services/notification/notification_service.dart';
import 'package:syncly/core/router/app_router.dart';
import 'package:syncly/core/repositories/auth_repository.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Give Firebase a moment to resolve persisted auth state.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final repo = ref.read(authRepositoryProvider);
      final isLoggedIn = await repo.isAuthenticated();

      if (!mounted) return;
      ref.read(appInitializingProvider.notifier).state = false;

      if (isLoggedIn) {
        context.go('/');
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref.read(notificationServiceProvider).handlePendingNavigation();
          }
        });
      } else {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      if (!mounted) return;
      ref.read(appInitializingProvider.notifier).state = false;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(AssetPaths.appLogo, width: 240, height: 240,),
              Text(
                'Syncly',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
