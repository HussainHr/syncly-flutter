import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Activates Firebase App Check so Auth/Firestore requests include a valid token.
///
/// Debug builds use debug providers (register the printed debug token in
/// Firebase Console → App Check → Manage debug tokens).
/// Release builds use Play Integrity (Android) and Device Check (iOS).
Future<void> configureAppCheck() async {
  if (kIsWeb) return;

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );
}
