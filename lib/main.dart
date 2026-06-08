import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncly/firebase_options.dart';
import 'core/config/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/presence_provider.dart';
import 'core/services/notification/notification_service.dart';
import 'features/settings/presentation/providers/settings_controller.dart';

// IMPORTANT: This MUST be a top-level function (outside of any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Create a temporary notification service instance for background handling
    final notificationService = NotificationService();
    await notificationService.handleRemoteMessage(
      message,
      fromBackground: true,
    );
  } catch (e) {
    debugPrint('Error in background handler: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Sign-In (google_sign_in v7+).
  await GoogleSignIn.instance.initialize();

  // Register the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Global Status Bar Style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Lock portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

// lib/main.dart - Update MyApp
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize notification service on start
      ref.read(notificationServiceProvider).init();
      // Presence tracking (online/last seen)
      ref.read(presenceServiceProvider).start();
    });

    // Keep notifications system in sync with Settings, and request permission once.
    ref.listen(settingsControllerProvider, (prev, next) async {
      final notif = ref.read(notificationServiceProvider);
      await notif.setEnabled(next.notificationsEnabled);

      if (next.notificationsEnabled && !next.notificationsPermissionAsked) {
        await notif.requestPermission();
        await ref
            .read(settingsControllerProvider.notifier)
            .markNotificationsPermissionAsked();
      }
    });

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(settingsControllerProvider).themeMode;

    return MaterialApp.router(
      title: 'Syncly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}