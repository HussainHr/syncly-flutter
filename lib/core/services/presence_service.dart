import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight presence tracking for Firestore `users/{uid}`.
///
/// - Sets `isOnline=true` on resume/init (when user is signed in)
/// - Sets `isOnline=false` on background (paused/inactive)
class PresenceService with WidgetsBindingObserver {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  PresenceService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  StreamSubscription<User?>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    _sub = _auth.authStateChanges().listen((u) async {
      if (u == null) return;
      await _setOnline(u.uid, true);
    });

    final u = _auth.currentUser;
    if (u != null) {
      await _setOnline(u.uid, true);
    }
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final u = _auth.currentUser;
    if (u == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_setOnline(u.uid, true));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_setOnline(u.uid, false));
    }
  }

  Future<void> _setOnline(String uid, bool online) async {
    try {
      await _db.collection('users').doc(uid).set({
        'isOnline': online,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Presence update failed: $e');
      }
    }
  }
}

