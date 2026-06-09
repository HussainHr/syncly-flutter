import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.10),
              colorScheme.tertiary.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sync_rounded,
                  size: 52,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Syncly',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Team messaging, in sync',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
