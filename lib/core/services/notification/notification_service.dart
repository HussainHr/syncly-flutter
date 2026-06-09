import 'dart:convert';
import 'dart:developer' as synclyLogger;
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncly/core/models/notification/local_notification_model.dart';
import 'package:syncly/core/router/app_router.dart';
import 'package:syncly/core/repositories/auth_repository.dart';
import 'notification_storage_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref? ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Map<String, dynamic>? _pendingNavigationData;
  bool _enabled = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inboxSub;
  StreamSubscription<String>? _tokenSub;
  final Set<String> _processedInboxIds = <String>{};

  NotificationService([this.ref]);

  Future<void> init() async {
    synclyLogger.log("🔧 Initializing NotificationService...");
    // Only init local notifications and FCM listeners on app start
    // Permission request moved to home screen
    await _initLocalNotifications();
    await _initFirebaseMessaging();

    // Print FCM Token on launch
    final token = await getFcmToken();
    if (token != null) {
      debugPrint('🚀 FCM TOKEN ON LAUNCH: $token');
      synclyLogger.log("🚀 FCM TOKEN ON LAUNCH: $token");
    }

    await _syncTokenToFirestore();

    // Keep token updated on refresh.
    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((_) {
      if (!_enabled) return;
      _syncTokenToFirestore();
    });

    // Start Firestore in-app notifications (works even without Blaze/Functions).
    _startInboxNotifications();
  }

  Future<void> requestPermission() async {
    synclyLogger.log("🔐 Requesting notification permission...");
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      synclyLogger.log(
        "📱 iOS permission status: ${settings.authorizationStatus}",
      );
    } else if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.notification.request();
        synclyLogger.log("📱 Android 13+ permission status: $status");
      }
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      await _messaging.setAutoInitEnabled(enabled);
      if (!enabled) {
        // Stop receiving new tokens/notifications for this device (can be re-created later).
        await _messaging.deleteToken();
      }
    } catch (e) {
      synclyLogger.log('Error updating FCM auto-init: $e');
    }

    if (!enabled) {
      await _inboxSub?.cancel();
      _inboxSub = null;
      _processedInboxIds.clear();
    } else {
      _startInboxNotifications();
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt >= 33;
  }

  Future<void> _initLocalNotifications() async {
    synclyLogger.log("🔔 Initializing local notifications...");
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _initFirebaseMessaging() async {
    synclyLogger.log("📲 Setting up Firebase messaging listeners...");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_enabled) return;
      synclyLogger.log("📥 Foreground FCM: ${message.notification?.title}");
      _handleMessage(message, showLocalNotification: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!_enabled) return;
      synclyLogger.log(
        "📲 Opened from background: ${message.notification?.title}",
      );
      _handleMessage(message);
      _handleNavigation(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (!_enabled) return;
      synclyLogger.log(
        "🕘 App launched via notification: ${initialMessage.notification?.title}",
      );
      _handleMessage(initialMessage);
      _pendingNavigationData = initialMessage.data;
    }
  }

  Future<void> _handleMessage(
    RemoteMessage message, {
    bool showLocalNotification = false,
  }) async {
    try {
      final model = LocalNotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        imageUrl:
            message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
        data: message.data,
        timestamp: DateTime.now(),
      );

      await NotificationStorageService.saveNotification(model);
      synclyLogger.log("💾 Notification saved to storage");

      if (showLocalNotification) {
        await _showLocalNotification(model);
      }
    } catch (e, s) {
      synclyLogger.log("❌ Error handling message: $e\n$s");
    }
  }

  Future<void> _showLocalNotification(LocalNotificationModel model) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = model.id.hashCode & 0x7fffffff;
      final payload = jsonEncode({
        'id': model.id,
        if (model.data != null) ...model.data!,
      });

      await _localNotifications.show(
        notificationId,
        model.title,
        model.body,
        details,
        payload: payload,
      );
      synclyLogger.log("📳 Local notification shown: ${model.title}");
    } catch (e, s) {
      synclyLogger.log("❌ Error showing local notification: $e\n$s");
    }
  }

  Future<void> _onLocalNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    synclyLogger.log("👆 Local notification tapped, payload: $payload");

    if (payload == null || payload.isEmpty) return;

    try {
      Map<String, dynamic>? data;
      String? notificationId;

      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
          notificationId = (decoded['id'] ?? '').toString();
        }
      } catch (_) {
        notificationId = payload;
      }

      if (data != null && data.containsKey('type')) {
        _handleNavigation(data);
      } else if (notificationId != null && notificationId.isNotEmpty) {
        final model = await NotificationStorageService.getNotificationById(
          notificationId,
        );
        if (model?.data != null) {
          _handleNavigation(model!.data!);
        }
      }

      if (notificationId != null && notificationId.isNotEmpty) {
        await NotificationStorageService.markAsRead(notificationId);
      }
    } catch (e, s) {
      synclyLogger.log("❌ Error handling tap: $e\n$s");
    }
  }

  void _handleNavigation(Map<String, dynamic> data) {
    if (ref == null) {
      synclyLogger.log("⚠️ Ref is null, cannot navigate");
      _pendingNavigationData = data;
      return;
    }

    final type = data['type'];
    synclyLogger.log("🧭 Navigating based on type: $type");

    final router = ref!.read(appRouterProvider);
    if (type == 'message') {
      final chatId = (data['chatId'] ?? '').toString();
      final fromUid = (data['fromUid'] ?? '').toString();
      if (chatId.isEmpty || fromUid.isEmpty) return;
      router.push('/chats/$chatId?otherUid=$fromUid');
      return;
    }

    if (type == 'friend_request') {
      final fromUid = (data['fromUid'] ?? '').toString();
      if (fromUid.isEmpty) return;
      router.push('/users/$fromUid');
      return;
    }

  }

  Future<void> handlePendingNavigation() async {
    if (_pendingNavigationData == null) return;
    synclyLogger.log("🕘 Processing pending notification navigation");
    _handleNavigation(_pendingNavigationData!);
    _pendingNavigationData = null;
  }

  Future<void> handleRemoteMessage(
    RemoteMessage message, {
    bool fromBackground = false,
  }) async {
    synclyLogger.log(
      "📥 handleRemoteMessage (bg=$fromBackground): ${message.notification?.title}",
    );
    await _handleMessage(
      message,
      showLocalNotification: fromBackground,
    );
  }

  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      synclyLogger.log('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _syncTokenToFirestore() async {
    if (ref == null) return;
    try {
      final auth = ref!.read(authRepositoryProvider);
      final uid = auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final token = await getFcmToken();
      if (token == null || token.isEmpty) return;

      final doc = _firestore.collection('users').doc(uid).collection('fcmTokens').doc(token);
      await doc.set({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other'),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      synclyLogger.log('Error syncing FCM token: $e');
    }
  }

  void _startInboxNotifications() {
    if (ref == null) return;
    if (!_enabled) return;

    final auth = ref!.read(authRepositoryProvider);
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    _inboxSub?.cancel();
    _inboxSub = _firestore
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snap) async {
      if (!_enabled) return;

      final newlyAdded = snap.docChanges
          .where((c) => c.type == DocumentChangeType.added)
          .map((c) => c.doc)
          .toList(growable: false);

      if (newlyAdded.isEmpty) return;

      final batch = _firestore.batch();
      for (final d in newlyAdded) {
        if (_processedInboxIds.contains(d.id)) continue;
        _processedInboxIds.add(d.id);

        final data = d.data();
        if (data == null) continue;

        final title = (data['title'] as String?) ?? 'Notification';
        final body = (data['body'] as String?) ?? '';

        final model = LocalNotificationModel(
          id: d.id,
          title: title,
          body: body,
          imageUrl: null,
          data: {
            ...data,
            'id': d.id,
          },
          timestamp: DateTime.now(),
        );

        await NotificationStorageService.saveNotification(model);
        await _showLocalNotification(model);

        batch.set(d.reference, {
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        await batch.commit();
      } catch (_) {
        // ignore
      }
    });
  }
}
